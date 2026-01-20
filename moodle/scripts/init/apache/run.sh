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
. /scripts/liblog.sh

# Load Apache environment
. /scripts/init/apache/apache-env.sh

info "** Starting Apache **"
exec "apache2ctl" -f "$APACHE_CONF_FILE" -D "FOREGROUND"
