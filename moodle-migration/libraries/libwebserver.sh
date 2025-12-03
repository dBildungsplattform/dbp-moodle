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
    info "Starting Apache in background"
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