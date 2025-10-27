#!/bin/bash

# Load logging library
# shellcheck disable=SC1090,SC1091
. /scripts/liblog.sh

# Einige moodlehq default env vars:
# https://github.com/moodlehq/moodle-php-apache/blob/main/root/usr/local/etc/php/conf.d/10-docker-php-moodle.ini

export ROOT_DIR="/usr/local/etc"

# Logging configuration (optional)
export MODULE="${MODULE:-php}"
export DEBUG="${DEBUG:-false}"

# Support *_FILE environment overrides
php_env_vars=(
    PHP_FPM_LISTEN_ADDRESS
    PHP_DATE_TIMEZONE
    PHP_ENABLE_OPCACHE
    PHP_MAX_EXECUTION_TIME
    PHP_MAX_INPUT_TIME
    PHP_MAX_INPUT_VARS
    PHP_MEMORY_LIMIT
    PHP_POST_MAX_SIZE
    PHP_UPLOAD_MAX_FILESIZE
    PHP_OPCACHE_ENABLED
)
for env_var in "${php_env_vars[@]}"; do
    file_env_var="${env_var}_FILE"
    if [[ -n "${!file_env_var:-}" ]]; then
        if [[ -r "${!file_env_var:-}" ]]; then
            export "${env_var}=$(< "${!file_env_var}")"
            unset "${file_env_var}"
        else
            echo "Warning: Skipping export of '${env_var}'. '${!file_env_var:-}' is not readable."
        fi
    fi
done
unset php_env_vars

# PHP configuration paths (official image layout)
export PHP_CONF_DIR="${ROOT_DIR}/php"
export PHP_CONF_FILE="${PHP_CONF_DIR}/php.ini"
export PHP_INI_SCAN_DIR="${PHP_CONF_DIR}/conf.d"
export PHP_BIN_DIR="/usr/local/bin"
export PHP_SBIN_DIR="/usr/local/sbin"
export PHP_EXTENSION_DIR="/usr/local/lib/php/extensions/no-debug-non-zts-20210902"
export PHP_INCLUDE_PATH=".:/usr/local/lib/php"

# PHP-FPM configuration
export PHP_FPM_CONF_FILE="${ROOT_DIR}/php-fpm.conf"
export PHP_FPM_POOL_CONF_DIR="${ROOT_DIR}/php-fpm.d"
export PHP_FPM_POOL_CONF_FILE="${PHP_FPM_POOL_CONF_DIR}/www.conf"

export PHP_FPM_PID_FILE="/dbp-moodle/php-fpm.pid"
export PHP_FPM_LISTEN_ADDRESS="${PHP_FPM_LISTEN_ADDRESS:-/var/run/php-fpm.sock}" # Default missing
export PHP_FPM_LOG_FILE="/proc/self/fd/2"  # logs to stderr by default

# System users (adjust if needed)
export PHP_FPM_DAEMON_USER="www-data"
export PHP_FPM_DAEMON_GROUP="www-data"

# PHP runtime configuration
export PHP_DATE_TIMEZONE="${PHP_DATE_TIMEZONE:-UTC}"
PHP_ENABLE_OPCACHE="${PHP_ENABLE_OPCACHE:-"${PHP_OPCACHE_ENABLED:-yes}"}"
export PHP_ENABLE_OPCACHE="${PHP_ENABLE_OPCACHE}"
export PHP_EXPOSE_PHP="0"
export PHP_MAX_EXECUTION_TIME="${PHP_MAX_EXECUTION_TIME:-300}"
export PHP_MAX_INPUT_TIME="${PHP_MAX_INPUT_TIME:-60}"
export PHP_MAX_INPUT_VARS="${PHP_MAX_INPUT_VARS:-1000}"
export PHP_MEMORY_LIMIT="${PHP_MEMORY_LIMIT:-256M}"
export PHP_POST_MAX_SIZE="${PHP_POST_MAX_SIZE:-33M}"
export PHP_UPLOAD_MAX_FILESIZE="${PHP_UPLOAD_MAX_FILESIZE:-32M}"
export PHP_OUTPUT_BUFFERING="8196"

# Custom environment variables may be defined below
