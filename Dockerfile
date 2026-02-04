FROM ubuntu:noble-20260113

# Install Python 3.12 (Ubuntu Noble default), venv, curl, and git
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 \
      python3-venv \
      curl \
      git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

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
