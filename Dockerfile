# This Dockerfile starts the entrypoint script to evaluate if a new moodle version exists and an update should be started.
FROM bitnami/moodle:4.1.10-debian-12-r5
RUN echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
USER root
ARG DEBUG=${DEBUG:-false}

RUN mkdir /scripts /plugins

COPY scripts/install/downloadPlugins.sh /scripts/downloadPlugins.sh
COPY scripts/install/phpRedisInstall.sh /scripts/phpRedisInstall.sh

COPY scripts/init/entrypoint.sh /scripts/entrypoint.sh
COPY scripts/init/moodleUpdateCheck.sh /scripts/moodleUpdateCheck.sh
COPY scripts/init/applyPluginState.sh /scripts/applyPluginState.sh

RUN chmod +x /scripts/entrypoint.sh /scripts/moodleUpdateCheck.sh /scripts/applyPluginState.sh /scripts/downloadPlugins.sh /scripts/phpRedisInstall.sh

COPY scripts/test/test-plugin-install-uninstall.sh /scripts/test-plugin-install-uninstall.sh
RUN if [[ "$DEBUG" = true ]]; then chmod +x /scripts/test-plugin-install-uninstall.sh; fi

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y curl gpg unzip autoconf php-dev php-redis; \
    [[ "$DEBUG" = true ]] && apt-get install -y nano; \
    rm -rf /var/lib/apt/lists/*

# Install moosh for plugin management
RUN curl -L https://github.com/tmuras/moosh/archive/refs/tags/1.21.tar.gz -o moosh.tar.gz && \
    mkdir /moosh && tar -xzvf moosh.tar.gz -C moosh/ --strip-components=1 && \
    mkdir /.moosh && \
    chmod 774 /.moosh &&\
    cd /moosh/ && \
    composer install && \
    ln -s /moosh/moosh.php /usr/local/bin/moosh

# Install plugins to the image
RUN /scripts/downloadPlugins.sh && if [[ "$DEBUG" = false ]]; then rm /scripts/downloadPlugins.sh; fi

# Install redis-php which is required for moodle to use redis
RUN /scripts/phpRedisInstall.sh && if [[ "$DEBUG" = false ]]; then rm /scripts/phpRedisInstall.sh; fi

ENTRYPOINT ["/scripts/entrypoint.sh"]