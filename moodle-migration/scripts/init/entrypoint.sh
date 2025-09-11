#!/bin/bash
# This entrypoint script needs to be adjusted to function without bitnami

# set -o errexit
set -o nounset
# set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load Moodle environment
. /scripts/init/moodle/moodle-env.sh

# Load libraries
. /scripts/liblog.sh
. /scripts/libwebserver.sh

moodle_path="/dbp-moodle/moodle"
moodle_backup_path="/dbp-moodle/moodledata/moodle-backup" # Das Backup script muss bezüglich der Pfade angepasst werden

maintenance_html_path="/dbp-moodle/moodledata/climaintenance.html"
update_in_progress_path="/dbp-moodle/moodledata/UpdateInProgress"
update_failed_path="/dbp-moodle/moodledata/UpdateFailed"
plugin_state_failed_path="/dbp-moodle/moodledata/PluginsFailed"

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

startDbpMoodleSetup() {
    info "Starting dbp Moodle setup"
    # /scripts/init/apache/apacheSetup.sh
    /scripts/init/php/phpSetup.sh
    /scripts/init/postgres/postgresSetup.sh
    MODULE=dbp info "Initial Moodle setup finished"
}

MODULE=dbp info "Starting Moodle"
# printSystemStatus

# Can handle new version and existing version.
startDbpMoodleSetup

# MODULE=dbp info "Create php.ini with redis config"
#This must be adjusted because we install php with apt-get and don't use the binary directly
# /bin/cp /moodleconfig/php-ini/php.ini /opt/bitnami/php/etc/conf.d/php.ini

#This is not relevant for the dependency configuration and setup
# if [[ ! -f "$update_failed_path" ]]; then
#     MODULE=dbp info "Starting Moodle Update Check"
#     if /scripts/updateCheck.sh; then
#         MODULE=dbp info "Finished Update Check"
#     else
#         MODULE=dbp error "Update failed! Continuing with previously installed moodle.."
#         setStatusFile "$update_failed_path" true
#     fi
# else
#     MODULE=dbp warn "Update failed previously. Skipping update check..."
# fi

# MODULE=dbp info "Start Moodle setup script after checking for proper version"
# /scripts/init/moodle/moodleSetup.sh
# /post-init.sh # https://github.com/bitnami/containers/blob/main/bitnami/moodle/5.0/debian-12/rootfs/post-init.sh
# upgrade_if_pending

# MODULE=dbp info "Replacing config.php file with ours"
# /bin/cp -p /moodleconfig/config-php/config.php /tmp/config.php
# mv /tmp/config.php /dbp-moodle/moodle/config.php

# if [ -f "/tmp/de.zip" ] && [ ! -d /bitnami/moodledata/lang/de ]; then \
#     MODULE=dbp info "Installing german language pack"
#     mkdir -p /dbp-moodle/moodledata/lang
#     unzip -q /tmp/de.zip -d /dbp-moodle/moodledata/lang
# fi

# upgrade_if_pending

# if [[ ! -f "$update_failed_path" ]] && [[ ! -f "$plugin_state_failed_path" ]]; then
#     MODULE=dbp info "Starting plugin installation"
#     if /scripts/pluginCheck.sh; then
#         MODULE=dbp info "Finished Plugin Install"
#     else
#         MODULE=dbp error "Plugin check failed! Continuing to start webserver with possibly compromised plugins"
#         setStatusFile "$plugin_state_failed_path" true
#     fi
# else
#     MODULE=dbp warn "Update or Plugin check failed previously. Skipping plugin check..."
# fi

# MODULE=dbp info "Finished all preparations! Starting Webserver"
# /scripts/moodle/run.sh # This script does not exist currently, evaluate during the moodle installation

# SLeep for testing purposes
sleep 2000