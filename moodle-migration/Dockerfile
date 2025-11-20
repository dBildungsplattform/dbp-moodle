# Our old Dockerfile build on top of this one: https://github.com/bitnami/containers/blob/main/bitnami/moodle/5.0/debian-12/Dockerfile
# In dem neuen Moodle Image sind die Abhängigkeiten bereits vorinstalliert, weshalb ein entpacken nicht weiter notwenig ist,
# jedoch müssen die postunpack.sh Abschnitte der Komponenten beachtet werden, da diese auch Konfigurationsschritte enthalten
# Für die Abhängigkeiten muss geprüft werden, ob Konfigurationen während der Bauzeit oder Laufzeit eingespielt werden müssen

FROM php:8.1.33-fpm-bookworm AS build
USER root
ARG MOODLE_VERSION=${MOODLE_VERSION:-"4.5.4"}
#This is the path moodle will be placed after downloading for our Moodle Update Pipeline
ARG MOODLE_PATH="/opt/dbp-moodle/moodle"
ARG EXTRA_LOCALES=""
ARG APACHE_VERSION=${APACHE_VERSION:-"2.4.57"}
ARG APACHE_DOWNLOAD_URL="https://snapshot.debian.org/archive/debian/20230408T145143Z/pool/main/a/apache2"

ARG WITH_ALL_LOCALES="no"
RUN mkdir /bitnami
RUN mkdir /dbp-moodle

COPY scripts/install /scripts/install
COPY scripts/init /scripts/init
COPY libraries /scripts

#Add user with ID 1001
RUN useradd moodle -u 1001

RUN chmod -R +x /scripts/
# Install psql Version 13.x like in the other bitnami moodle image
# Currently permission problems here
RUN apt-get update && \
    apt-get install -y wget gpg curl acl gnupg jq ca-certificates cron locales git unzip autoconf
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update && \
    apt-get install -y postgresql-client-13

# Install apache2 and its dependencies
RUN apt-get install -y libapr1 libaprutil1 libaprutil1-dbd-sqlite3 libaprutil1-ldap libexpat1 liblua5.3-0 media-types procps && \
    curl -LO ${APACHE_DOWNLOAD_URL}/apache2-bin_${APACHE_VERSION}-1_amd64.deb && \
    curl -LO ${APACHE_DOWNLOAD_URL}/apache2-data_${APACHE_VERSION}-1_all.deb && \
    curl -LO ${APACHE_DOWNLOAD_URL}/apache2-utils_${APACHE_VERSION}-1_amd64.deb && \
    curl -LO ${APACHE_DOWNLOAD_URL}/apache2_${APACHE_VERSION}-1_amd64.deb && \
    dpkg -i *.deb && \
    apt-get install -y libapache2-mod-fcgid && \
    rm *.deb

#Install other dependencies
RUN apt-get install -y nano gettext libpq5 libedit2 libfontconfig1 libfreetype6 libglib2.0-0 libjpeg62-turbo liblcms2-2 libltdl7 libmagickcore-6.q16-6 libmagickwand-6.q16-6 libmemcached11 libpcre3 libpng16-16 libtidy5deb1 libwebp7 libxslt1.1 libzip4 libbz2-dev


# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin --filename=composer

# Install moosh for plugin management
# Because of current problems with moosh and no new release we use commit hashes. This one is the version bump to 1.34
RUN curl -L https://github.com/tmuras/moosh/archive/1d679882fca0a28facff7ec2b52e5b0f3eb61e2c.tar.gz -o moosh.tar.gz && \
    mkdir /moosh && tar -xzvf moosh.tar.gz -C /moosh/ --strip-components=1
RUN mkdir /.moosh &&\
    chmod 774 /.moosh &&\
    cd /moosh/ && \
    composer install && \
    ln -s /moosh/moosh.php /usr/local/bin/moosh

RUN /scripts/install/downloadMoodle.sh

# Hardening
RUN apt-get update && apt-get upgrade -y && \
    apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives
RUN apt-get update && apt-get upgrade -y && \
    apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives
RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true
RUN sed -i -e '/pam_loginuid.so/ s/^#*/#/' /etc/pam.d/cron

RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=C.UTF-8 LC_MESSAGES=en_US.UTF-8

RUN chmod +x /scripts/install/generate-locales.sh && \
    /scripts/install/generate-locales.sh

COPY /scripts/init/apache/httpd.conf /etc/apache2/apache2.conf

RUN /scripts/install/apacheInstall.sh

# Php configuration and installation
RUN /scripts/install/phpInstall.sh

# Prepare Moodle
RUN chmod -R g+w /etc/apache2/
RUN /scripts/install/moodleInstall.sh

EXPOSE 8080 8443

# Install plugins to the image
RUN mkdir /plugins && /scripts/install/downloadPlugins.sh

# RUN apt-get remove -y curl && \
#     apt-get autoremove -y

RUN chmod -R g+w /opt/dbp-moodle
#TODO replace the current /bitnami/moodle with /dbp-moodle/moodle
RUN chmod -R g+w /dbp-moodle
RUN chown 1001:1001 -R /bitnami
RUN chown 1001:1001 -R /dbp-moodle

RUN chown 1001:root -R /scripts
RUN chown 1001:root -R /plugins

RUN chown 1001:1001 -R /var/log/apache2
RUN chown 1001:1001 -R /etc/apache2
RUN chown 1001:1001 -R /usr/local/etc/php
RUN chown 1001:1001 -R /opt/dbp-moodle

USER 1001

ENTRYPOINT ["/scripts/init/entrypoint.sh"]