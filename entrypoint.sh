#!/bin/bash
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load Moodle environment
. /opt/bitnami/scripts/moodle-env.sh

# Load libraries
. /opt/bitnami/scripts/libbitnami.sh
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libwebserver.sh

info "=== Starting moodleUpdateCheck ===\n"
/moodleUpdateCheck.sh 2>&1 | tee -a "/bitnami/moodledata/moodleUpdateCheck.log"
EXIT_CODE=${PIPESTATUS[0]}
if [ $EXIT_CODE -eq 0 ]; then
    info "=== moodleUpdateCheck finished ===\n"
else
    error "=== moodleUpdateCheck failed! ===\n"
    error "Check /bitnami/moodledata/moodleUpdateCheck.log\n"
fi

print_welcome_page

info "** Starting Bitnami Moodle setup **"
/opt/bitnami/scripts/"$(web_server_type)"/setup.sh # SRE comment: this is apache for us
# /opt/bitnami/scripts/apache/setup.sh
/opt/bitnami/scripts/php/setup.sh
/opt/bitnami/scripts/mysql-client/setup.sh
/opt/bitnami/scripts/postgresql-client/setup.sh
/opt/bitnami/scripts/moodle/setup.sh
/post-init.sh
info "** Bitnami Moodle setup finished! **"
echo ""

info "Replacing config.php & php.ini"
/bin/cp -p /moodleconfig/config.php /bitnami/moodle/config.php
/bin/cp /moodleconfig/php.ini /opt/bitnami/php/etc/conf.d/php.ini

# touch /bitnami/moodledata/FreshInstall # is this still needed?

info "=== Starting Server! ==="

/opt/bitnami/scripts/moodle/run.sh