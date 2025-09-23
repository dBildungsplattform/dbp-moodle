#!/bin/bash
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load libraries
. /scripts/libfs.sh
. /scripts/liblog.sh
. /scripts/libapache.sh

# Load Apache environment
. /scripts/init/apache/apache-env.sh

# Ensure Apache environment variables are valid
apache_validate

# Ensure Apache daemon user exists when running as 'root'
am_i_root && ensure_user_exists "$APACHE_DAEMON_USER" --group "$APACHE_DAEMON_GROUP"

# TODO SSL configuration

# Update ports in configuration
[[ -n "$APACHE_HTTP_PORT_NUMBER" ]] && info "Configuring the HTTP port" && apache_configure_http_port "$APACHE_HTTP_PORT_NUMBER"
[[ -n "$APACHE_HTTPS_PORT_NUMBER" ]] && info "Configuring the HTTPS port" && apache_configure_https_port "$APACHE_HTTPS_PORT_NUMBER"

# Configure ServerTokens with user values
[[ -n "$APACHE_SERVER_TOKENS" ]] && info "Configuring Apache ServerTokens directive" && apache_configure_server_tokens "$APACHE_SERVER_TOKENS"

# Fix logging issue when running as root
! am_i_root || chmod o+w "$(readlink /dev/stdout)" "$(readlink /dev/stderr)"
