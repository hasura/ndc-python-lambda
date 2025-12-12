FROM python:3.12-slim

RUN python -m pip install --no-cache-dir --upgrade "pip>=25.3"

# Install curl for healthcheck
RUN apt-get update && \
    apt-get install -y curl git && \
    rm -rf /var/lib/apt/lists/*

# Security updates for CVE-2024-56406 (Perl), CVE-2025-7709 (SQLite)
# Upgrade vulnerable system packages to their fixed versions
RUN apt-get update && \
    apt-get upgrade -y \
      libperl5.40 \
      perl \
      perl-modules-5.40 \
      perl-base \
      libsqlite3-0 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY /docker /scripts
COPY /functions /functions

# Ensure scripts are executable
RUN chmod +x /scripts/package-restore.sh /scripts/start.sh

# Run the package-restore script
RUN /scripts/package-restore.sh

EXPOSE 8080

HEALTHCHECK --interval=5s --timeout=10s --start-period=1s --retries=3 \
    CMD [ "bash", "-c", "exec curl -f http://localhost:${HASURA_CONNECTOR_PORT:-8080}/health" ]

CMD [ "/scripts/start.sh" ]
