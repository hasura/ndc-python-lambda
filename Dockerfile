FROM ubuntu:noble-20260113

# Install dependencies and add deadsnakes PPA for latest Python
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      software-properties-common \
      gpg-agent && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      python3.13 \
      python3.13-venv \
      curl \
      git && \
    apt-get purge -y software-properties-common gpg-agent && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create python symlinks for compatibility
RUN ln -sf /usr/bin/python3.13 /usr/bin/python && \
    ln -sf /usr/bin/python3.13 /usr/bin/python3

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
