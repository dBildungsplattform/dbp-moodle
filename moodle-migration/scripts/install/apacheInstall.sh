#!/bin/bash
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load libraries
. /scripts/libapache.sh
. /scripts/libfs.sh
. /scripts/liblog.sh

# Load Apache environment
. /scripts/init/apache/apache-env.sh

apache_setup_config() {
    local template_dir="/scripts/init/apache/templates"
    
    # Enable Apache modules
    local -a modules_to_enable=(
        "deflate_module"
        "negotiation_module"
        "proxy[^\s]*_module"
        "rewrite_module"
        "slotmem_shm_module"
        "socache_shmcb_module"
        "ssl_module"
        "status_module"
    )
    for module in "${modules_to_enable[@]}"; do
        apache_enable_module "$module"
    done

    # Disable Apache modules
    local -a modules_to_disable=(
        "http2_module"
        "proxy_hcheck_module"
        "proxy_html_module"
        "proxy_http2_module"
    )
    for module in "${modules_to_disable[@]}"; do
        apache_disable_module "$module"
    done

    # Default vhost as fallback
    ensure_dir_exists "${APACHE_VHOSTS_DIR}"
    envsubst < "${template_dir}/default.conf.tpl" > "${APACHE_VHOSTS_DIR}/default.conf"
    envsubst < "${template_dir}/default-ssl.conf.tpl" > "${APACHE_VHOSTS_DIR}/default-ssl.conf"
    ensure_dir_exists "${APACHE_BASE_DIR}/htdocs"

    # Add new configuration only once, to avoid a second postunpack run breaking Apache
    local apache_conf_add
    apache_conf_add="$(cat <<EOF
PidFile "${APACHE_PID_FILE}"
TraceEnable Off
ServerTokens ${APACHE_SERVER_TOKENS}
IncludeOptional "${APACHE_CONF_DIR}/*.conf"
IncludeOptional "${APACHE_BASE_DIR}/mods-enabled/*.load"
IncludeOptional "${APACHE_BASE_DIR}/mods-enabled/*.conf"
IncludeOptional "${APACHE_BASE_DIR}/sites-enabled/*.conf"
IncludeOptional "${APACHE_VHOSTS_DIR}/*.conf"
EOF
)"
    ensure_apache_configuration_exists "$apache_conf_add" "TraceEnable Off" # "${APACHE_CONF_DIR}/test/test.conf"

    # Configure the default ports since the container is non root by default
    apache_configure_http_port "$APACHE_DEFAULT_HTTP_PORT_NUMBER"
    apache_configure_https_port "$APACHE_DEFAULT_HTTPS_PORT_NUMBER"

    # Remove unnecessary directories that come with the tarball
    # rm -rf "${APACHE_ROOT_DIR}/certs" "${APACHE_ROOT_DIR}/conf" TODO check later on
}

apache_setup_php_config() {
    apache_php_conf_file="${APACHE_CONF_DIR}/php.conf"
    cat > "$apache_php_conf_file" <<EOF
AddType application/x-httpd-php .php
DirectoryIndex index.html index.htm index.php
EOF
    ensure_apache_configuration_exists "Include \"${apache_php_conf_file}\""
}

apache_setup_config
apache_setup_php_config

# Ensure non-root user has write permissions on a set of directories
chmod -R g+w "$APACHE_BASE_DIR"
for dir in "$APACHE_CONF_DIR" "$APACHE_LOGS_DIR" "$APACHE_VHOSTS_DIR" "$APACHE_DEFAULT_CONF_DIR"; do
    ensure_dir_exists "$dir"
    chmod -R g+rwX "$dir"
done

# Create 'apache2' symlink pointing to the 'apache' directory, for compatibility with Bitnami Docs guides
ln -sf apache "${APACHE_ROOT_DIR}/apache2"

ln -sf "/dev/stdout" "${APACHE_LOGS_DIR}/access_log"
ln -sf "/dev/stderr" "${APACHE_LOGS_DIR}/error_log"

# This file is necessary for avoiding the error
# "unable to write random state"
# Source: https://stackoverflow.com/questions/94445/using-openssl-what-does-unable-to-write-random-state-mean

touch /.rnd && chmod g+rw /.rnd
