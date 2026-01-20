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
. /scripts/libos.sh
. /scripts/liblog.sh

# Load PHP-FPM environment variables
. /scripts/init/php/php-env.sh

error_code=0

php_initialize # Should also include customization of the php.ini file

if is_php_fpm_not_running; then
    exec php-fpm -F --pid $PHP_FPM_PID_FILE -y $PHP_FPM_CONF_FILE >/dev/null 2>&1 &
    if ! retry_while "is_php_fpm_running"; then
        error "php-fpm did not start"
        error_code=1
    else
        info "php-fpm started"
    fi
else
    info "php-fpm is already running"
fi

exit "$error_code"
