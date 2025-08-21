FROM moodlehq/moodle-php-apache:8.1-bookworm AS build
USER root
ARG MOODLE_VERSION=${MOODLE_VERSION:-"4.5.4"}
ARG MOODLE_PATH="/dbp-moodle/moodle"
RUN mkdir /dbp-moodle

COPY scripts/install/downloadMoodle.sh /downloadMoodle.sh
# COPY scripts/install/downloadPlugins.sh /downloadPlugins.sh

RUN chmod +x /downloadMoodle.sh
# /downloadPlugins.sh

# Install psql Version 13.x like in the other bitnami moodle image
RUN apt-get update && \
    apt-get install -y wget gpg curl gnupg jq ca-certificates && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y postgresql-client-13

RUN /downloadMoodle.sh

# Install plugins to the image
RUN mkdir /plugins 
# && /downloadPlugins.sh

# Moodle setup.sh script calls moodle_initialize() which installs moodle
# COPY scripts/init/entrypoint.sh /scripts/entrypoint.sh