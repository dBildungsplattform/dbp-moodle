# This Dockerfile starts the entrypoint script to evaluate if a new moodle version exists and an update should be started.
# Stage 1: Build stage
FROM bitnami/moodle:4.1.10-debian-12-r0 AS build
USER root
ARG MOODLE_VERSION=${MOODLE_VERSION:-"4.1.10"}

COPY scripts/install/downloadMoodle.sh /downloadMoodle.sh
COPY scripts/install/downloadPlugins.sh /downloadPlugins.sh
# COPY scripts/install/phpRedisInstall.sh /phpRedisInstall.sh

RUN chmod +x /downloadMoodle.sh /downloadPlugins.sh

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y curl wget gpg jq && \
    rm -rf /var/lib/apt/lists/*

# Install moosh for plugin management
RUN curl -L https://github.com/tmuras/moosh/archive/refs/tags/1.21.tar.gz -o moosh.tar.gz && \
    mkdir /moosh && tar -xzvf moosh.tar.gz -C moosh/ --strip-components=1 && \
    mkdir /.moosh && \
    chmod 774 /.moosh &&\
    cd /moosh/ && \
    composer install && \
    ln -s /moosh/moosh.php /usr/local/bin/moosh

RUN /downloadMoodle.sh

# Install plugins to the image
RUN mkdir /plugins && /downloadPlugins.sh

# Install redis-php which is required for moodle to use redis
# RUN /scripts/phpRedisInstall.sh

# Stage 2: Production stage
FROM bitnami/moodle:4.1.10-debian-12-r0
ARG MOODLE_VERSION=${MOODLE_VERSION:-"4.1.10"}
ARG DEBUG=${DEBUG:-true} # TODO change back after dev

RUN echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen

COPY --from=build "/moodle-${MOODLE_VERSION}.tgz" "/moodle-${MOODLE_VERSION}.tgz"
COPY --from=build /moosh /moosh
COPY --from=build /plugins /plugins

COPY scripts/init/entrypoint.sh /scripts/entrypoint.sh
COPY scripts/init/updateCheck.sh /scripts/updateCheck.sh
COPY scripts/init/pluginCheck.sh /scripts/pluginCheck.sh
# TODO: ideally move phpRedisInstall to build stage and just use the artifacts
COPY scripts/install/phpRedisInstall.sh /phpRedisInstall.sh

COPY scripts/test/test-plugin-install-uninstall.sh /scripts/test-plugin-install-uninstall.sh

RUN chmod +x /scripts/entrypoint.sh /scripts/updateCheck.sh /scripts/pluginCheck.sh /phpRedisInstall.sh
RUN if [[ "$DEBUG" = true ]]; then chmod +x /scripts/test-plugin-install-uninstall.sh; fi

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y curl unzip autoconf php-dev php-redis; \
    [[ "$DEBUG" = true ]] && apt-get install -y nano; \
    rm -rf /var/lib/apt/lists/*

# Install redis-php which is required for moodle to use redis
RUN /phpRedisInstall.sh

ENTRYPOINT ["tail", "-f", "/dev/null"]
# ENTRYPOINT ["/scripts/entrypoint.sh"]
