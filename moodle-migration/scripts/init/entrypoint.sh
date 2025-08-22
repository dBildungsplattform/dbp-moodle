#!/bin/bash
# This entrypoint script needs to be adjusted to function without bitnami

# set -o errexit
set -o nounset
# set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load Moodle environment
. /opt/bitnami/scripts/moodle-env.sh

# Load libraries
. /opt/bitnami/scripts/liblog.sh  #Diese werden wir wahrscheinlich übernehmen
. /opt/bitnami/scripts/libwebserver.sh # Prüfen ob und was notwendig ist

moodle_path="/bitnami/moodle"
moodle_backup_path="/bitnami/moodledata/moodle-backup" # Das Backup script muss bezüglich der Pfade angepasst werden

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
    info "Starting Bitnami Moodle setup"
    /opt/bitnami/scripts/"$(web_server_type)"/setup.sh # apacheSetup.sh
    /opt/bitnami/scripts/php/setup.sh # phpSetup.sh
    /opt/bitnami/scripts/postgresql-client/setup.sh # postgresSetup.sh
    MODULE=dbp info "Bitnami Moodle setup finished"
}

MODULE=dbp info "Starting Moodle"
printSystemStatus

# Bitnami setup now always runs.
# Can handle new version and existing version.
startBitnamiSetup

MODULE=dbp info "Create php.ini with redis config"
/bin/cp /moodleconfig/php-ini/php.ini /opt/bitnami/php/etc/conf.d/php.ini

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
/opt/bitnami/scripts/moodle/setup.sh # moodleSetup.sh
/post-init.sh # https://github.com/bitnami/containers/blob/main/bitnami/moodle/5.0/debian-12/rootfs/post-init.sh
upgrade_if_pending

MODULE=dbp info "Replacing config.php file with ours"
/bin/cp -p /moodleconfig/config-php/config.php /tmp/config.php
mv /tmp/config.php /bitnami/moodle/config.php

if [ -f "/tmp/de.zip" ] && [ ! -d /bitnami/moodledata/lang/de ]; then \
    MODULE=dbp info "Installing german language pack"
    mkdir -p /bitnami/moodledata/lang
    unzip -q /tmp/de.zip -d /bitnami/moodledata/lang
fi

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
