#!/bin/bash
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load libraries
. /scripts/libphp.sh
. /scripts/libfile.sh
. /scripts/libos.sh

# Load PHP-FPM environment variables
. /scripts/init/php/php-env.sh

BUILD_PACKAGES="libcurl4-openssl-dev libfreetype6-dev libicu-dev libjpeg62-turbo-dev \
  libldap2-dev libmariadb-dev libmemcached-dev libpng-dev libpq-dev libxml2-dev libxslt-dev \
  uuid-dev libbz2-dev libzip-dev zlib1g-dev libgmp-dev libssl-dev libreadline-dev \
  libsqlite3-dev libtidy-dev libjpeg-dev libwebp-dev libxpm-dev pkg-config"

apt-get update && apt-get install -y --no-install-recommends $BUILD_PACKAGES


# Prüfen was wir hier brauchen
# https://github.com/moodlehq/moodle-php-apache/blob/main/root/tmp/setup/php-extensions.sh
# All the extensions from bitnami: apcu.so  imagick.so  maxminddb.so  memcached.so  mongodb.so  opcache.so  pdo_dblib.so  pdo_pgsql.so  pgsql.so  redis.so  xdebug.so

# ZIP
docker-php-ext-configure zip --with-zip
docker-php-ext-install zip

docker-php-ext-install -j$(nproc) \
    exif intl mysqli opcache pgsql soap xsl bcmath bz2 calendar exif gmp iconv intl ldap pcntl pdo pdo_mysql pgsql soap sockets tidy xsl zip

# GD.
docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/
docker-php-ext-install -j$(nproc) gd

# # Ensure PHP-FPM daemon user exists and required folder belongs to this user when running as 'root'
# if am_i_root; then
#     ensure_user_exists "$PHP_FPM_DAEMON_USER" --group "$PHP_FPM_DAEMON_GROUP"
#     ensure_dir_exists "$PHP_TMP_DIR"
#     chown -R "${PHP_FPM_DAEMON_USER}:${PHP_FPM_DAEMON_GROUP}" "$PHP_TMP_DIR"
#     # Enable daemon configuration
#     if [[ ! -f "${PHP_CONF_DIR}/common.conf" ]]; then
#         cp "${PHP_CONF_DIR}/common.conf.disabled" "${PHP_CONF_DIR}/common.conf"
#     fi
# fi

# Cleanup after source build
apt-get remove --purge -y $BUILD_PACKAGES
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

# This step copies the provided php.ini template fpr production as the default php.ini whcih can be modified later on
cp ${PHP_CONF_DIR}/php.ini-production $PHP_CONF_FILE

chmod -R g+w "$PHP_CONF_DIR"
# Fix logging issue when running as root
! am_i_root || chmod o+w "$(readlink /dev/stdout)" "$(readlink /dev/stderr)"

# Prüfen ob wir hardening für das default PHP und unsere settings benötigen

# Ich muss die php extensions noch installieren