FROM postgres:16-alpine

LABEL maintainer="AuthVault Enterprise Security Team"
LABEL description="Dedicated PostgreSQL image for AuthVault with pre-configured schemas and indexes"

COPY init/*.sql /docker-entrypoint-initdb.d/

HEALTHCHECK --interval=5s --timeout=3s --retries=5 \
    CMD pg_isready -U ${POSTGRES_USER:-vault_user} -d ${POSTGRES_DB:-authvault} || exit 1
