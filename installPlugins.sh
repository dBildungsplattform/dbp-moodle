#!/bin/bash
set -e

RED='\033[0;31m'
GRN='\033[0;32m'
NC='\033[0m' # No Color

cur_image_version="$APP_VERSION"

moodle_path="/bitnami/moodle"
plugin_zip_path="/plugins"

# indicator files
update_plugins_path="/bitnami/moodledata/UpdatePlugins"
update_failed_path="/bitnami/moodledata/UpdateFailed"
update_cli_path="/bitnami/moodledata/CliUpdate"
maintenance_html_path="/bitnami/moodledata/climaintenance.html"

# data folders
new_version_data_path="/bitnami/moodledata/updated-moodle"
old_version_data_path="/bitnami/moodledata/moodle-backup"


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

install_plugins() {
    rm -f "$update_plugins_path"
    if [[ $ENABLE_KALTURA == "True" ]]; then
        printf "=== Kaltura Flag enabled, installing Kaltura plugin ===\n"
        install_kaltura
    fi

    if [ -d "/tmp/plugins/" ]; then
        rm -rf /tmp/plugins/
    fi
    mkdir /tmp/plugins/

    for plugin in $MOODLE_PLUGINS; do
        IFS=':' read -r -a parts <<< "$plugin"
        plugin_name="${parts[0]}"
        plugin_fullname="${parts[1]}"
        plugin_path="${parts[2]}"
        
        printf 'Installing plugin %s (%s) to path "%s"\n' "$plugin_name" "$plugin_fullname" "$plugin_path"
        unzip -q "${plugin_zip_path}/${plugin_fullname}.zip" -d /tmp/plugins/
        mkdir -p "${moodle_path}/${plugin_path}"
        mv "/tmp/plugins/${plugin_name}"/* "${moodle_path}/${plugin_path}"
    done

    # Run Moodle DB upgrade
    php $moodle_path/admin/cli/upgrade.php --non-interactive
    #rm -rf "$plugin_zip_path"
}

install_plugins
rm -f "$maintenance_html_path"
exit 0
