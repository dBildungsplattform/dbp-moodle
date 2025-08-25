# Our old Dockerfile build on top of this one: https://github.com/bitnami/containers/blob/main/bitnami/moodle/5.0/debian-12/Dockerfile
# In dem neuen Moodle Image sind die Abhängigkeiten bereits vorinstalliert, weshalb ein entpacken nicht weiter notwenig ist,
# jedoch müssen die postunpack.sh Abschnitte der Komponenten beachtet werden, da diese auch Konfigurationsschritte enthalten
# Für die Abhängigkeiten muss geprüft werden, ob Konfigurationen während der Bauzeit oder Laufzeit eingespielt werden müssen
FROM moodlehq/moodle-php-apache:8.1-bookworm AS build
USER root
ARG MOODLE_VERSION=${MOODLE_VERSION:-"4.5.4"}
ARG MOODLE_PATH="/dbp-moodle/moodle"
ARG EXTRA_LOCALES
ARG WITH_ALL_LOCALES="no"
RUN mkdir /dbp-moodle

COPY scripts/install/downloadMoodle.sh /downloadMoodle.sh
# COPY scripts/install/downloadPlugins.sh /downloadPlugins.sh

RUN chmod +x /downloadMoodle.sh
# /downloadPlugins.sh

# Install psql Version 13.x like in the other bitnami moodle image
RUN apt-get update && \
    apt-get install -y wget gpg curl acl gnupg jq ca-certificates cron && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y postgresql-client-13

RUN /downloadMoodle.sh

# Hardening
# RUN apt-get update && apt-get upgrade -y && \
#     apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives
# RUN apt-get update && apt-get upgrade -y && \
#     apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives
# RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true
# RUN sed -i -e '/pam_loginuid.so/ s/^#*/#/' /etc/pam.d/cron

# Das locale-gen Skript wurde in dem vorherigen Dockerimage nach opt/bitnami kopiert
# RUN echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen && \
#     locale-gen && \
#     update-locale LANG=de_DE.UTF-8 LC_MESSAGES=de_DE.UTF-8


# RUN /opt/bitnami/scripts/locales/generate-locales.sh
# RUN /opt/bitnami/scripts/apache/postunpack.sh
# RUN /opt/bitnami/scripts/php/postunpack.sh
# RUN /opt/bitnami/scripts/apache-modphp/postunpack.sh
# RUN /opt/bitnami/scripts/moodle/postunpack.sh
# RUN /opt/bitnami/scripts/mysql-client/postunpack.sh
# ENV APACHE_HTTPS_PORT_NUMBER="" \
#     APACHE_HTTP_PORT_NUMBER="" \
#     APP_VERSION="5.0.1" \
#     BITNAMI_APP_NAME="moodle" \
#     LANG="en_US.UTF-8" \
#     LANGUAGE="en_US:en" \
#     PATH="/opt/bitnami/common/bin:/opt/bitnami/php/bin:/opt/bitnami/php/sbin:/opt/bitnami/apache/bin:/opt/bitnami/postgresql/bin:/opt/bitnami/mysql/bin:$PATH"

# EXPOSE 8080 8443

# Install plugins to the image
RUN mkdir /plugins 
# && /downloadPlugins.sh

# COPY scripts/init/entrypoint.sh /scripts/entrypoint.sh
# COPY scripts/init/updateCheck.sh /scripts/updateCheck.sh
# COPY scripts/init/pluginCheck.sh /scripts/pluginCheck.sh
# COPY scripts/install/phpRedisInstall.sh /phpRedisInstall.sh

#Der vorherige Ordner, wo die Bitnami Skripte abgelegt sind
RUN chown 1001:root -R /opt/bitnami
RUN chown 1001:root -R /plugins

# ENTRYPOINT ["/scripts/entrypoint.sh"]