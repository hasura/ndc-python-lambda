FROM us-docker.pkg.dev/hasura-container-images/external-images/docker.io/library/ubuntu:noble-stable

# Install Python 3.12 (Ubuntu Noble default), venv, curl, and git.
# libbrotli1 is installed explicitly so this layer pulls the patched Ubuntu
# Noble security build (>= 1.1.0-2ubuntu0.1) rather than whatever version the
# base image happens to ship.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 \
      python3-venv \
      curl \
      git \
      libbrotli1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Fail closed: ensure the patched libbrotli1 security update is present so an
# unpatched base image is never silently treated as fixed.
RUN installed_brotli="$(dpkg-query -W -f='${Version}' libbrotli1)" && \
    echo "libbrotli1 installed version: ${installed_brotli}" && \
    dpkg --compare-versions "${installed_brotli}" ge 1.1.0-2ubuntu0.1 || \
      { echo "ERROR: libbrotli1 ${installed_brotli} is older than required 1.1.0-2ubuntu0.1" >&2; exit 1; }

# Create python symlink for compatibility
RUN ln -sf /usr/bin/python3 /usr/bin/python

COPY /docker /scripts
COPY /functions /functions

# Ensure scripts are executable
RUN chmod +x /scripts/package-restore.sh /scripts/start.sh

# Run the package-restore script
RUN /scripts/package-restore.sh

# Create non-root user
RUN useradd -m python && \
    chown -R python:python /scripts /functions

USER python

EXPOSE 8080

HEALTHCHECK --interval=5s --timeout=10s --start-period=1s --retries=3 \
    CMD [ "bash", "-c", "exec curl -f http://localhost:${HASURA_CONNECTOR_PORT:-8080}/health" ]

CMD [ "/scripts/start.sh" ]
