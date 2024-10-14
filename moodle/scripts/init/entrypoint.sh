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
plugin_state_failed_path="/bitnami/moodledata/PluginsFailed"

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
    if [[ -e $plugin_state_failed_path ]]; then
        MODULE=dbp error "PluginsFailed file exists!"
    fi
}

setStatusFile() {
    local path="$1"
    local enable="$2"
    if [ "$enable" = true ]; then
        touch "$path"
    elif [ "$enable" = false ]; then
        rm -f "$path"
    fi
}

upgrade_if_pending() {
    set +o errexit
    result=$(php "${moodle_path}/admin/cli/upgrade.php" --is-pending 2>&1)

    EXIT_CODE=$?
    set -o errexit
    # If an upgrade is needed it exits with an error code of 2 so it distinct from other types of errors.
    if [ $EXIT_CODE -eq 0 ]; then
        MODULE="dbp-plugins" info 'No upgrade needed'
    elif [ $EXIT_CODE -eq 1 ]; then
        MODULE="dbp-plugins" error 'Call to upgrade.php failed... Can not continue installation'
        MODULE="dbp-plugins" error "$result"
        exit 1
    elif [ $EXIT_CODE -eq 2 ]; then
        MODULE="dbp-plugins" info 'Running Moodle upgrade'
        php "${moodle_path}/admin/cli/upgrade.php" --non-interactive
    fi
}

startBitnamiSetup() {
    print_welcome_page
    info "Starting Bitnami Moodle setup"
    /opt/bitnami/scripts/"$(web_server_type)"/setup.sh
    /opt/bitnami/scripts/php/setup.sh
    /opt/bitnami/scripts/mysql-client/setup.sh
    /opt/bitnami/scripts/postgresql-client/setup.sh
    # These lines are run later, after update check
    # /opt/bitnami/scripts/moodle/setup.sh 
    # /post-init.sh
    MODULE=dbp info "Bitnami Moodle setup finished"
}

MODULE=dbp info "Starting Moodle"
printSystemStatus

# Bitnami setup now always runs.
# Can handle new version and existing version.
startBitnamiSetup

if [[ ! -f "$update_failed_path" ]]; then
    MODULE=dbp info "Starting Moodle Update Check"
    if /scripts/updateCheck.sh; then
        MODULE=dbp info "Finished Update Check"
    else
        MODULE=dbp error "Update failed! Continuing with previously installed moodle.."
        setStatusFile "$update_failed_path" true
    fi
else
    MODULE=dbp warn "Update failed previously. Skipping update check..."
fi

MODULE=dbp info "Start Bitnami setup script after checking for proper version"
/opt/bitnami/scripts/moodle/setup.sh
/post-init.sh
upgrade_if_pending

MODULE=dbp info "Replacing config files with ours"
/bin/cp -p /moodleconfig/config.php /bitnami/moodle/config.php
/bin/cp /moodleconfig/php.ini /opt/bitnami/php/etc/conf.d/php.ini
upgrade_if_pending

if [[ ! -f "$update_failed_path" ]] && [[ ! -f "$plugin_state_failed_path" ]]; then
    MODULE=dbp info "Starting plugin installation"
    if /scripts/pluginCheck.sh; then
        MODULE=dbp info "Finished Plugin Install"
    else
        MODULE=dbp error "Plugin check failed! Continuing to start webserver with possibly compromised plugins"
        setStatusFile "$plugin_state_failed_path" true
    fi
else
    MODULE=dbp warn "Update or Plugin check failed previously. Skipping plugin check..."
fi


MODULE=dbp info "Finished all preparations! Starting Webserver"
/opt/bitnami/scripts/moodle/run.sh