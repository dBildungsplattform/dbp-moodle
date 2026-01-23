# This Dockerfile starts the entrypoint script to evaluate if a new moodle version exists and an update should be started.

# Stage 1: Build stage
FROM bitnamilegacy/moodle:4.5.4-debian-12-r0 AS build
USER root
ARG MOODLE_VERSION=${MOODLE_VERSION:-"4.5.4"}

COPY scripts/install/downloadMoodle.sh /downloadMoodle.sh
COPY scripts/install/downloadPlugins.sh /downloadPlugins.sh
# COPY scripts/install/phpRedisInstall.sh /phpRedisInstall.sh

RUN chmod +x /downloadMoodle.sh /downloadPlugins.sh

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y curl wget gpg jq zip git && \
    rm -rf /var/lib/apt/lists/*

# Install moosh for plugin management
# Because of current problems with moosh and no new release we use commit hashes. This one is the version bump to 1.34
RUN curl -L https://github.com/tmuras/moosh/archive/1d679882fca0a28facff7ec2b52e5b0f3eb61e2c.tar.gz -o moosh.tar.gz && \
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
FROM bitnamilegacy/moodle:4.5.4-debian-12-r0
ARG MOODLE_VERSION=${MOODLE_VERSION:-"4.5.4"}
ARG DEBUG=${DEBUG:-false}

RUN echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen

COPY --from=build "/moodle-${MOODLE_VERSION}.tgz" "/moodle-${MOODLE_VERSION}.tgz"
COPY --from=build /moosh /moosh
COPY --from=build /plugins /plugins

COPY scripts/init/entrypoint.sh /scripts/entrypoint.sh
COPY scripts/init/updateCheck.sh /scripts/updateCheck.sh
COPY scripts/init/pluginCheck.sh /scripts/pluginCheck.sh
COPY scripts/install/phpRedisInstall.sh /phpRedisInstall.sh

COPY scripts/test/test-plugin-install-uninstall.sh /scripts/test-plugin-install-uninstall.sh

RUN chmod +x /scripts/entrypoint.sh /scripts/updateCheck.sh /scripts/pluginCheck.sh /phpRedisInstall.sh
RUN if [[ "$DEBUG" = true ]]; then chmod +x /scripts/test-plugin-install-uninstall.sh; fi

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y curl unzip autoconf php-dev php-redis; \
    [[ "$DEBUG" = true ]] && apt-get install -y nano; \
    rm -rf /var/lib/apt/lists/*

# dependencies for stack plugin
RUN apt-get update && apt-get install -y maxima gnuplot;

# Install redis-php which is required for moodle to use redis
RUN /phpRedisInstall.sh

RUN MAJOR_MINOR=$(echo "$MOODLE_VERSION" | cut -d. -f1,2) && \
    curl -L https://download.moodle.org/download.php/direct/langpack/${MAJOR_MINOR}/de.zip --output /tmp/de.zip

RUN chown 1001:root -R /opt/bitnami
RUN chown 1001:root -R /plugins

ENTRYPOINT ["/scripts/entrypoint.sh"]