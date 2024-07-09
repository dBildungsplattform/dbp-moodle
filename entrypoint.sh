#!/bin/bash

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

printf "=== Starting moodleUpdateCheck ===\n"

bitnamiSetup() {
    print_welcome_page
    info "** Starting Moodle setup **"
    /opt/bitnami/scripts/"$(web_server_type)"/setup.sh
    /opt/bitnami/scripts/php/setup.sh
    /opt/bitnami/scripts/mysql-client/setup.sh
    /opt/bitnami/scripts/postgresql-client/setup.sh
    /opt/bitnami/scripts/moodle/setup.sh
    /post-init.sh
    info "** Moodle setup finished! **"
}

# /moodleUpdateCheck.sh 2>&1 | tee -a "/bitnami/moodledata/moodleUpdateCheck.log"
# EXIT_CODE=${PIPESTATUS[0]}

if [[ ! -d "/bitnami/moodle/" || ! -f "/bitnami/moodle/version.php" || ! -d "/opt/bitnami/php/etc/conf.d/" ]]; then
    bitnamiSetup
fi

# replace config with ours
/bin/cp -p /moodleconfig/config.php /bitnami/moodle/config.php
/bin/cp /moodleconfig/php.ini /opt/bitnami/php/etc/conf.d/php.ini

MODULE=dbp info "Starting plugin installation"
/tmp/installPlugins.sh
MODULE=dbp info "Finished Plugin Install"

# touch /bitnami/moodledata/FreshInstall
MODULE=dbp info "Finished all preperations! Starting Webserver"

/opt/bitnami/scripts/moodle/run.sh
