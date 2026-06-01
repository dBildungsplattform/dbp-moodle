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


RUNTIME_PACKAGES="\
  libicu76 libtidy58 libzip4 zlib1g libpq5 libldap-2.5-0 libpng16-16 \
  libjpeg62-turbo libwebp7 libxpm4 libxml2 libxslt1.1 libsqlite3-0 libgmp10 libssl3 libreadline8 libbz2-1.0"

apt-get update && apt-get install -y --no-install-recommends $BUILD_PACKAGES $RUNTIME_PACKAGES

docker-php-ext-install -j$(nproc) \
    bcmath bz2 calendar exif gd gmp iconv intl ldap mysqli opcache pcntl pdo pdo_mysql pgsql soap sockets tidy xsl zip

# GD.
docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/

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