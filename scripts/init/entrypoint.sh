#!/bin/bash

# set -o errexit
set -o nounset
# set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load Moodle environment
. /opt/bitnami/scripts/moodle-env.sh

# Load libraries
. /opt/bitnami/scripts/libbitnami.sh
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libwebserver.sh

MODULE=dbp info "** Starting Moodle **"

startBitnamiSetup() {
    print_welcome_page
    info "** Starting Bitnami Moodle setup **"
    /opt/bitnami/scripts/"$(web_server_type)"/setup.sh
    /opt/bitnami/scripts/php/setup.sh
    /opt/bitnami/scripts/mysql-client/setup.sh
    /opt/bitnami/scripts/postgresql-client/setup.sh
    /opt/bitnami/scripts/moodle/setup.sh
    /post-init.sh
    MODULE=dbp info "** Bitnami Moodle setup finished! **"
}

# if true || [[ ! -d "/bitnami/moodle/" || ! -f "/bitnami/moodle/version.php" || ! -d "/opt/bitnami/php/etc/conf.d/" ]]; then

# Bitnami setup now always runs.
# Can handle new version and existing version.
# TODO: check if it can handle existing lower version. e.g. skript is moodle 4.1.11 and existing is 4.1.10
startBitnamiSetup

MODULE=dbp info "** Starting Moodle Update Check **"
/scripts/moodleUpdateCheck.sh 2>&1 | tee -a "/bitnami/moodledata/moodleUpdateCheck.log"

MODULE=dbp info "** Update Check finished! **"
# 

MODULE=dbp info "Replacing config files with ours"
/bin/cp -p /moodleconfig/config.php /bitnami/moodle/config.php
/bin/cp /moodleconfig/php.ini /opt/bitnami/php/etc/conf.d/php.ini

MODULE=dbp info "Starting plugin installation"
/scripts/applyPluginState.sh
MODULE=dbp info "Finished Plugin Install"

# touch /bitnami/moodledata/FreshInstall

MODULE=dbp info "Finished all preperations! Starting Webserver"
/opt/bitnami/scripts/moodle/run.sh