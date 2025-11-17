#!/bin/bash
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0
#
# Bitnami web server handler library

# shellcheck disable=SC1090,SC1091

# Load generic libraries
. /scripts/liblog.sh

# This is a general wrapper around the apache webserver used by moodle setup

########################
# Execute a command (or list of commands) with the web server environment and library loaded
# Globals:
#   *
# Arguments:
#   None
# Returns:
#   None
#########################
web_server_execute() {
    local -r web_server="${1:?missing web server}"
    shift
    # Run program in sub-shell to avoid web server environment getting loaded when not necessary
    (
        . "/scripts/libapache.sh"
        . "/scripts/init/apache/apache-env.sh"
        "$@"
    )
}

########################
# Validate that a supported web server is configured
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#########################
# Migrated
web_server_validate() {
    local error_code=0

    # Auxiliary functions
    print_validation_error() {
        error "$1"
        error_code=1
    }

    if ! web_server_execute apache type -t "is_apache_running" >/dev/null; then
        print_validation_error "Could not load the apache web server library from /scripts. Check that it exists and is readable."
    fi

    return "$error_code"
}


########################
# Start web server
# Globals:
#   *
# Arguments:
#   None
# Returns:
#   None
#########################
web_server_start() {
    info "Starting $(web_server_type) in background"
    "/scripts/init/apache/run.sh"
}

########################
# Ensure a web server application configuration is updated with the runtime configuration (i.e. ports)
# It serves as a wrapper for the specific web server function
# Globals:
#   *
# Arguments:
#   $1 - App name
# Flags:
#   --hosts - Host listen addresses
#   --server-name - Server name
#   --server-aliases - Server aliases
#   --enable-http - Enable HTTP app configuration (if not enabled already)
#   --enable-https - Enable HTTPS app configuration (if not enabled already)
#   --disable-http - Disable HTTP app configuration (if not disabled already)
#   --disable-https - Disable HTTPS app configuration (if not disabled already)
#   --http-port - HTTP port number
#   --https-port - HTTPS port number
# Returns:
#   true if the configuration was updated, false otherwise
########################
# Migration: With only one call and only one argument, the whole case section wont be run at all
# Basically just calls web_server_execute which executes apache_update_app_configuration "moodle"
web_server_update_app_configuration() {
    local app="${1:?missing app}"
    shift
    local -a args web_servers
    args=("$app")
    # Validate arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            # Common flags
            --enable-http \
            | --enable-https \
            | --disable-http \
            | --disable-https \
            )
                args+=("$1")
                ;;
            --hosts \
            | --server-name \
            | --server-aliases \
            | --http-port \
            | --https-port \
            )
                args+=("$1" "${2:?missing value}")
                shift
                ;;

            *)
                echo "Invalid command line flag $1" >&2
                return 1
                ;;
        esac
        shift
    done
    web_server_execute apache "apache_update_app_configuration" "${args[@]}"
}

########################
# Ensure a web server application configuration exists (i.e. Apache virtual host format or NGINX server block)
# It serves as a wrapper for the specific web server function
# Globals:
#   *
# Arguments:
#   $1 - App name
# Flags:
#   --type - Application type, which has an effect on which configuration template to use
#   --hosts - Host listen addresses
#   --server-name - Server name
#   --server-aliases - Server aliases
#   --allow-remote-connections - Whether to allow remote connections or to require local connections
#   --disable - Whether to render server configurations with a .disabled prefix
#   --disable-http - Whether to render the app's HTTP server configuration with a .disabled prefix
#   --disable-https - Whether to render the app's HTTPS server configuration with a .disabled prefix
#   --http-port - HTTP port number
#   --https-port - HTTPS port number
#   --document-root - Path to document root directory
# Apache-specific flags:
#   --apache-additional-configuration - Additional vhost configuration (no default)
#   --apache-additional-http-configuration - Additional HTTP vhost configuration (no default)
#   --apache-additional-https-configuration - Additional HTTPS vhost configuration (no default)
#   --apache-before-vhost-configuration - Configuration to add before the <VirtualHost> directive (no default)
#   --apache-allow-override - Whether to allow .htaccess files (only allowed when --move-htaccess is set to 'no' and type is not defined)
#   --apache-extra-directory-configuration - Extra configuration for the document root directory
#   --apache-proxy-address - Address where to proxy requests
#   --apache-proxy-configuration - Extra configuration for the proxy
#   --apache-proxy-http-configuration - Extra configuration for the proxy HTTP vhost
#   --apache-proxy-https-configuration - Extra configuration for the proxy HTTPS vhost
#   --apache-move-htaccess - Move .htaccess files to a common place so they can be loaded during Apache startup (only allowed when type is not defined)
# NGINX-specific flags:
#   --nginx-additional-configuration - Additional server block configuration (no default)
#   --nginx-external-configuration - Configuration external to server block (no default)
# Returns:
#   true if the configuration was enabled, false otherwise
########################
ensure_web_server_app_configuration_exists() {
    local app="${1:?missing app}"
    shift
    local -a apache_args nginx_args web_servers args_var
    apache_args=("$app")
    nginx_args=("$app")
    # Validate arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            # Common flags
            --disable \
            | --disable-http \
            | --disable-https \
            )
                apache_args+=("$1")
                nginx_args+=("$1")
                ;;
            --hosts \
            | --server-name \
            | --server-aliases \
            | --type \
            | --allow-remote-connections \
            | --http-port \
            | --https-port \
            | --document-root \
            )
                apache_args+=("$1" "${2:?missing value}")
                nginx_args+=("$1" "${2:?missing value}")
                shift
                ;;

            # Specific Apache flags
            --apache-additional-configuration \
            | --apache-additional-http-configuration \
            | --apache-additional-https-configuration \
            | --apache-before-vhost-configuration \
            | --apache-allow-override \
            | --apache-extra-directory-configuration \
            | --apache-proxy-address \
            | --apache-proxy-configuration \
            | --apache-proxy-http-configuration \
            | --apache-proxy-https-configuration \
            | --apache-move-htaccess \
            )
                apache_args+=("${1//apache-/}" "${2:?missing value}")
                shift
                ;;

            # Specific NGINX flags
            --nginx-additional-configuration \
            | --nginx-external-configuration)
                nginx_args+=("${1//nginx-/}" "${2:?missing value}")
                shift
                ;;

            *)
                echo "Invalid command line flag $1" >&2
                return 1
                ;;
        esac
        shift
    done
    args_var="apache_args[@]"
    web_server_execute "apache" "ensure_apache_app_configuration_exists" "${!args_var}"
}
