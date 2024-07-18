#!/usr/bin/env sh
set -eu -o pipefail

/scripts/package-restore.sh

cd /functions

# Activate virtual environment if it exists
if [ -f "venv/bin/activate" ]; then
  source venv/bin/activate
fi

# Run the Python script with the serve command
python3 functions.py serve --configuration ./
