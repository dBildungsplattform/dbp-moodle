#!/bin/bash
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0

# shellcheck disable=SC1090,SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load Moodle environment
. /scripts/init/moodle/moodle-env.sh

# Load PostgreSQL Client environment for 'postgresql_remote_execute' (after 'discourse-env.sh' so that MODULE is not set to a wrong value)
if [[ -f /scripts/init/postgres/postgresql-client-env.sh ]]; then
    . /scripts/init/postgres/postgresql-client-env.sh
fi

# Load PHP environment for cron configuration (after 'moodle-env.sh' so that MODULE is not set to a wrong value)
. /scripts/init/php/php-env.sh

# Load libraries
. /scripts/libmoodle.sh
. /scripts/libwebserver.sh

# Load web server environment and functions (after 'moodle-env.sh' file so MODULE is not set to a wrong value)
. "/scripts/init/apache/apache-env.sh"

# Ensure Moodle environment variables are valid
moodle_validate

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

# Update web server configuration with runtime environment (needs to happen before the initialization)
web_server_update_app_configuration "moodle"

# Ensure Moodle is initialized
moodle_initialize
