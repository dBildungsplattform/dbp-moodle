#!/bin/bash
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0
# Bitnami Postunpack
# Will be executed during build time

# shellcheck disable=SC1090,SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load Moodle environment
. /scripts/init/moodle/moodle-env.sh

# Load PHP environment for 'php_conf_set' (after 'moodle-env.sh' so that MODULE is not set to a wrong value)
. /scripts/init/php/php-env.sh

# Load libraries
. /scripts/libphp.sh
. /scripts/libmoodle.sh
. /scripts/libfile.sh
. /scripts/libfs.sh
. /scripts/libos.sh
. /scripts/liblog.sh
. /scripts/libwebserver.sh

# Load web server environment and functions (after Moodle environment file so MODULE is not set to a wrong value)
. /scripts/init/apache/apache-env.sh

# Ensure the Moodle base directory exists and has proper permissions
info "Configuring file permissions for Moodle"
ensure_user_exists "$WEB_SERVER_DAEMON_USER" --group "$WEB_SERVER_DAEMON_GROUP"
for dir in "$MOODLE_BASE_DIR" "$MOODLE_VOLUME_DIR" "$MOODLE_DATA_DIR"; do
    ensure_dir_exists "$dir"
    # Use daemon:root ownership for compatibility when running as a non-root user
    configure_permissions_ownership "$dir" -d "775" -f "664" -u "1001" -g "1001"
done

# Configure required PHP options for application to work properly, based on build-time defaults
info "Configuring default PHP options for Moodle"
php_conf_set memory_limit "$PHP_DEFAULT_MEMORY_LIMIT"
php_conf_set max_input_vars "$PHP_DEFAULT_MAX_INPUT_VARS"
php_conf_set extension "pgsql"

# Enable default web server configuration for Moodle
# TODO
info "Creating default web server configuration for Moodle"
web_server_validate
ensure_web_server_app_configuration_exists "moodle" --type php --apache-additional-configuration '
RewriteEngine On

RewriteRule ^/phpmyadmin - [L,NC]
RewriteRule "(\/vendor\/)" - [F]
RewriteRule "(\/node_modules\/)" - [F]
RewriteRule "(^|/)\.(?!well-known\/)" - [F]
RewriteRule "(composer\.json)" - [F]
RewriteRule "(\.lock)" - [F]
RewriteRule "(\/environment.xml)" - [F]
Options -Indexes
RewriteRule "(\/install.xml)" - [F]
RewriteRule "(\/README)" - [F]
RewriteRule "(\/readme)" - [F]
RewriteRule "(\/moodle_readme)" - [F]
RewriteRule "(\/upgrade\.txt)" - [F]
RewriteRule "(phpunit\.xml\.dist)" - [F]
RewriteRule "(\/tests\/behat\/)" - [F]
RewriteRule "(\/fixtures\/)" - [F]

RewriteRule "(\/package\.json)" - [F]
RewriteRule "(\/Gruntfile\.js)" - [F]
'

# Copy all initially generated configuration files to the default directory
# (this is to avoid breaking when entrypoint is being overridden)
# TODO adjust paths
# cp -r "/opt/bitnami/apache/conf"/* "/opt/bitnami/apache/conf.default"
# cp -r "$APACHE_CONF_DIR/* "/opt/bitnami/apache/conf.default"

# This is necessary for the libpersistence.sh scripts to work when running as non-root
chmod g+w /opt/dbp-moodle