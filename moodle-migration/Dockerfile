FROM moodlehq/moodle-php-apache:8.1-bookworm AS build
USER root

# Install psql Version 13.x like in the other bitnami moodle image
RUN apt-get update && \
    apt-get install -y wget gpg curl gnupg ca-certificates && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y postgresql-client-13

