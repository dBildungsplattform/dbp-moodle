#!/bin/bash
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0
#
# Bitnami web server handler library

# shellcheck disable=SC1090,SC1091

# Load generic libraries
. /opt/bitnami/scripts/liblog.sh

# Because this is a general wrapper around the apache webserver, i intend to strip it away and use the apache functions directly if possible

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
web_server_validate() {
    local error_code=0
    local supported_web_servers=("apache")

    # Auxiliary functions
    print_validation_error() {
        error "$1"
        error_code=1
    }

    if [[ -z "$(web_server_type)" || ! " ${supported_web_servers[*]} " == *" $(web_server_type) "* ]]; then
        print_validation_error "Could not detect any supported web servers. It must be one of: ${supported_web_servers[*]}"
    elif ! web_server_execute "$(web_server_type)" type -t "is_$(web_server_type)_running" >/dev/null; then
        print_validation_error "Could not load the $(web_server_type) web server library from /opt/bitnami/scripts. Check that it exists and is readable."
    fi

    return "$error_code"
}

########################
# Check whether the web server is running
# Globals:
#   *
# Arguments:
#   None
# Returns:
#   true if the web server is running, false otherwise
#########################
is_web_server_running() {
    "is_$(web_server_type)_running"
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
    if [[ "${BITNAMI_SERVICE_MANAGER:-}" = "systemd" ]]; then
        systemctl start "bitnami.$(web_server_type).service"
    else
        "${BITNAMI_ROOT_DIR}/scripts/$(web_server_type)/start.sh"
    fi
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
