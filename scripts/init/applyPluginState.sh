#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load Moodle environment
. /opt/bitnami/scripts/liblog.sh


RED='\033[0;31m'
GRN='\033[0;32m'
NC='\033[0m' # No Color

moodle_path="/bitnami/moodle"
plugin_zip_path="/plugins"
plugin_unzip_path="/tmp/plugins/"

# indicator files
update_plugins_path="/bitnami/moodledata/UpdatePlugins"
update_failed_path="/bitnami/moodledata/UpdateFailed"
update_cli_path="/bitnami/moodledata/CliUpdate"
maintenance_html_path="/bitnami/moodledata/climaintenance.html"

last_installed_plugin=""
cleanup_failed_install() {
    if [[ -n "$last_installed_plugin" ]]; then
        rm -rf "$last_installed_plugin"
    fi
}

install_kaltura(){
    local kaltura_url="https://moodle.org/plugins/download.php/29483/Kaltura_Video_Package_moodle41_2022112803.zip"
    local kaltura_save_path="/bitnami/moodle/kaltura.zip"
    curl "$kaltura_url" --output "$kaltura_save_path"
    if [ ! -f "$kaltura_save_path" ]; then
        printf "===${RED} Kaltura could not be downloaded, please check for correct Kaltura Url and try again ${NC}===\n"
        printf "\tCurrent kaltura url: %s\n" "$kaltura_url"
        return 1
    fi
    printf "\tUnpacking Kaltura\n"
    unzip -q "$kaltura_save_path" -d "/bitnami/moodle/"
    printf "\tInstalling Kaltura\n"
    php /bitnami/moodle/admin/cli/upgrade.php --non-interactive
    printf "\tDeleting install artifacts\n"
    rm "$kaltura_save_path"
    printf "===${GRN} Kaltura plugin successfully installed ${NC}===\n"
}

install_plugin() {
    local plugin_name
    local plugin_fullname
    local plugin_path

    plugin_name="$1"
    plugin_fullname="$2"
    plugin_path="$3"

    unzip -q "${plugin_zip_path}/${plugin_fullname}.zip" -d "$plugin_unzip_path"
    mkdir -p "${moodle_path}/${plugin_path}"
    mv "${plugin_unzip_path}${plugin_name}" "${moodle_path}/${plugin_parent_path:?}/"
}

uninstall_plugin() {
    local plugin_fullname
    local plugin_path
    plugin_fullname="$1"
    plugin_path="$2"

    php "${moodle_path}/admin/cli/uninstall_plugins.php" --plugins="$plugin_fullname" --run
    rm -rf "${moodle_path:?}/${plugin_path:?}"
}

upgrade_if_pending() {
    set +o errexit
    php "${moodle_path}/admin/cli/upgrade.php" --is-pending > /dev/null 2>&1

    EXIT_CODE=$?
    set -o errexit
    # If an upgrade is needed it exits with an error code of 2 so it distinct from other types of errors.
    if [ $EXIT_CODE -eq 2 ]; then
        MODULE="dbp-plugins" info 'Running Moodle upgrade'
        php "${moodle_path}/admin/cli/upgrade.php" --non-interactive
    else
        MODULE="dbp-plugins" info 'No upgrade needed'
    fi
}

main() {
    rm -f "$update_plugins_path"

    if [[ $ENABLE_KALTURA == "True" ]]; then
        printf "=== Kaltura Flag enabled, installing Kaltura plugin ===\n"
        install_kaltura
    fi

    if [ -d "$plugin_unzip_path" ]; then
        rm -rf "$plugin_unzip_path"
    fi
    mkdir "$plugin_unzip_path"

    anychange=false

    for plugin in $MOODLE_PLUGINS; do
        IFS=':' read -r -a parts <<< "$plugin"
        plugin_name="${parts[0]}"
        plugin_fullname="${parts[1]}"
        plugin_path="${parts[2]}"
        plugin_enabled="${parts[3]}"

        plugin_parent_path=$(dirname "$plugin_path")
        full_path="${moodle_path}/${plugin_path}"

        plugin_installed=false

        if [ -d "$full_path" ]; then
            plugin_installed=true
        fi

        if [ "$plugin_enabled" = "$plugin_installed" ]; then
            continue
        fi

        if [ "$plugin_enabled" = true ]; then
            last_installed_plugin="$full_path"
            MODULE="dbp-plugins" info "Installing plugin ${plugin_name} (${plugin_fullname}) to path \"${plugin_path}\""
            install_plugin "$plugin_name" "$plugin_fullname" "$plugin_path"
            last_installed_plugin=""
            anychange=true

        elif [ "$plugin_enabled" = false ]; then
            MODULE="dbp-plugins" info "Uninstalling plugin ${plugin_name} (${plugin_fullname}) from path \"${plugin_path}\""
            uninstall_plugin "$plugin_fullname" "$plugin_path"
            anychange=true
        else
            MODULE="dbp-plugins" info 'Unexpected value for plugin_enabled: "%s". Expecting "true/false". Exiting...' "$plugin_enabled"
            exit 1
        fi
    done
    
    
    if [ "$anychange" = true ]; then
        upgrade_if_pending
    else
        MODULE="dbp-plugins" info 'No plugin state change detected.'
    fi

    # clean up some files
    rm -rf "$plugin_unzip_path"
    rm -f "$maintenance_html_path" # TODO move this to entrypoint probably
}

trap cleanup_failed_install ERR
main