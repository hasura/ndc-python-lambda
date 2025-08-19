#!/bin/bash

# Script to build, test, and cleanup the ndc-python-lambda container
# This script builds the root Dockerfile, runs it with connector-definition files,
# tests the /schema and /capabilities endpoints, and cleans up.

set -e # Exit on any error

# Configuration
IMAGE_NAME="ndc-python-lambda-test"
CONTAINER_NAME="ndc-python-lambda-test-container"
CONTAINER_PORT="8080"
HOST_PORT="8080"
TIMEOUT=30        # seconds to wait for container to be ready
TEMP_BUILD_DIR="" # Will be set by mktemp

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Function to cleanup on exit
cleanup() {
  print_status "Cleaning up..."

  # Stop and remove container if it exists
  if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    print_status "Stopping and removing container: ${CONTAINER_NAME}"
    docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true
  fi

  # Remove image if it exists
  if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${IMAGE_NAME}:latest$"; then
    print_status "Removing image: ${IMAGE_NAME}"
    docker rmi "${IMAGE_NAME}" >/dev/null 2>&1 || true
  fi

  # Remove temporary build directory if it exists
  if [ -n "${TEMP_BUILD_DIR}" ] && [ -d "${TEMP_BUILD_DIR}" ]; then
    print_status "Removing temporary build directory: ${TEMP_BUILD_DIR}"
    rm -rf "${TEMP_BUILD_DIR:?}"
  fi

  print_status "Cleanup completed"
}

# Set trap to cleanup on script exit
trap cleanup EXIT

# Function to wait for container to be ready
wait_for_container() {
  print_status "Waiting for container to be ready..."
  local count=0
  while [ $count -lt $TIMEOUT ]; do
    if curl -s -f "http://localhost:${HOST_PORT}/health" >/dev/null 2>&1; then
      print_status "Container is ready!"
      return 0
    fi
    sleep 1
    count=$((count + 1))
    echo -n "."
  done
  echo
  print_error "Container failed to become ready within ${TIMEOUT} seconds"
  return 1
}

# Function to setup temporary build directory
setup_temp_build_dir() {
  print_status "Setting up temporary build directory with connector-definition files..."

  # Create temporary directory using mktemp
  TEMP_BUILD_DIR=$(mktemp -d)
  print_status "Created temporary build directory: ${TEMP_BUILD_DIR}"

  # Copy the Dockerfile to temp directory
  cp "Dockerfile" "${TEMP_BUILD_DIR}/"

  # Copy connector-definition files to the locations expected by the Dockerfile
  # The original Dockerfile expects:
  # COPY /docker /scripts  -> so we copy connector-definition/scripts to docker/
  # COPY /functions /functions -> so we copy connector-definition/template to functions/

  # cp -r "connector-definition/scripts" "${TEMP_BUILD_DIR}/docker"
  cp -r "docker" "${TEMP_BUILD_DIR}/docker"
  cp -r "connector-definition/template" "${TEMP_BUILD_DIR}/functions"

  print_status "Temporary build directory setup complete"
  print_status "Build directory contents:"
  ls -la "${TEMP_BUILD_DIR}"
}

# Function to test an endpoint
test_endpoint() {
  local endpoint=$1
  local description=$2

  print_status "Testing ${description} (${endpoint})..."

  local response_code
  response_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${HOST_PORT}${endpoint}")

  if [ "$response_code" = "200" ]; then
    print_status "✓ ${description} returned 200 OK"
    return 0
  else
    print_error "✗ ${description} returned ${response_code} (expected 200)"
    return 1
  fi
}

# Main execution
main() {
  print_status "Starting ndc-python-lambda container test"

  # Check if required directories exist
  if [ ! -d "connector-definition/template" ]; then
    print_error "connector-definition/template directory not found"
    exit 1
  fi

  if [ ! -d "connector-definition/scripts" ]; then
    print_error "connector-definition/scripts directory not found"
    exit 1
  fi

  # Setup temporary build directory with connector-definition files
  setup_temp_build_dir

  # Build the Docker image using the original Dockerfile from temp directory
  print_status "Building Docker image: ${IMAGE_NAME}"
  docker build -t "${IMAGE_NAME}" "${TEMP_BUILD_DIR}"

  # Run the container
  print_status "Starting container: ${CONTAINER_NAME}"
  docker run -d \
    --name "${CONTAINER_NAME}" \
    -p "${HOST_PORT}:${CONTAINER_PORT}" \
    "${IMAGE_NAME}"

  # Wait for container to be ready
  if ! wait_for_container; then
    print_error "Container failed to start properly"
    exit 1
  fi

  # Test the endpoints
  local test_failed=false

  if ! test_endpoint "/schema" "Schema endpoint"; then
    test_failed=true
  fi

  if ! test_endpoint "/capabilities" "Capabilities endpoint"; then
    test_failed=true
  fi

  # Report results
  if [ "$test_failed" = true ]; then
    print_error "Some tests failed!"
    exit 1
  else
    print_status "All tests passed successfully! ✓"
  fi
}

# Check if Docker is available
if ! command -v docker &>/dev/null; then
  print_error "Docker is not installed or not in PATH"
  exit 1
fi

# Check if curl is available
if ! command -v curl &>/dev/null; then
  print_error "curl is not installed or not in PATH"
  exit 1
fi

# Run main function
main

print_status "Script completed successfully!"
