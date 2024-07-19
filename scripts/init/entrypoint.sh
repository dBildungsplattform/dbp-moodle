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

moodle_path="/bitnami/moodle"
moodle_backup_path="/bitnami/moodledata/moodle-backup"

maintenance_html_path="/bitnami/moodledata/climaintenance.html"
update_in_progress_path="/bitnami/moodledata/UpdateInProgress"
update_failed_path="/bitnami/moodledata/UpdateFailed"

printSystemStatus() {
    if [[ -e $maintenance_html_path ]]; then
        MODULE=dbp warn "climaintenance.html file exists."
    fi
    if [[ -e $update_in_progress_path ]]; then
        MODULE=dbp warn "UpdateInProgress file exists."
    fi
    if [[ -e $update_failed_path ]]; then
        MODULE=dbp error "UpdateFailed file exists!"
    fi
}

restoreLocalBackup() {
    cp -rp "${moodle_backup_path}/"* "${moodle_path}/"
}

startBitnamiSetup() {
    print_welcome_page
    info "** Starting Bitnami Moodle setup **"
    /opt/bitnami/scripts/"$(web_server_type)"/setup.sh
    /opt/bitnami/scripts/php/setup.sh
    /opt/bitnami/scripts/mysql-client/setup.sh
    /opt/bitnami/scripts/postgresql-client/setup.sh
    # /opt/bitnami/scripts/moodle/setup.sh
    /post-init.sh
    MODULE=dbp info "** Bitnami Moodle setup finished! **"
}

MODULE=dbp info "** Starting Moodle **"
printSystemStatus

# Bitnami setup now always runs.
# Can handle new version and existing version.
# TODO: check if it can handle existing lower version. e.g. skript is moodle 4.1.11 and existing is 4.1.10
startBitnamiSetup

MODULE=dbp info "** Starting Moodle Update Check **"
/scripts/moodleUpdateCheck.sh

MODULE=dbp info "Start Bitnami setup script after checking for proper version"
/opt/bitnami/scripts/moodle/setup.sh
/post-init.sh

MODULE=dbp info "Replacing config files with ours"
/bin/cp -p /moodleconfig/config.php /bitnami/moodle/config.php
/bin/cp /moodleconfig/php.ini /opt/bitnami/php/etc/conf.d/php.ini

MODULE=dbp info "Starting plugin installation"
/scripts/applyPluginState.sh
MODULE=dbp info "Finished Plugin Install"

# touch /bitnami/moodledata/FreshInstall

MODULE=dbp info "Finished all preparations! Starting Webserver"
/opt/bitnami/scripts/moodle/run.sh