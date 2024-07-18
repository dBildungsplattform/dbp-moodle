#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load Moodle environment
. /opt/bitnami/scripts/liblog.sh

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

install_plugin() {
    local plugin_name
    local plugin_fullname
    local plugin_path

    plugin_name="$1"
    plugin_fullname="$2"
    plugin_path="$3"

    unzip -q "${plugin_zip_path}/${plugin_fullname}.zip" 
    mkdir -p "${moodle_path}/${plugin_path}"
    mv "${plugin_unzip_path}${plugin_name}" "${moodle_path}/${plugin_parent_path:?}/"
}

uninstall_plugin() {
    local plugin_fullname
    local plugin_path
    plugin_fullname="$1"
    plugin_path="$2"

    if [[ "$plugin_fullname" == "kaltura" ]]; then 
        uninstall_kaltura
        return
    fi
    php "${moodle_path}/admin/cli/uninstall_plugins.php" --plugins="$plugin_fullname" --run
    rm -rf "${moodle_path:?}/${plugin_path:?}"
    rm -rf "${moodle_path:?}/"
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

applyKalturaState() {
    target_state="$1"
    kaltura_dirs=(
        "blocks/kalturamediagallery"
        "filter/kaltura"
        "lib/editor/atto/plugins/kalturamedia"
        "lib/editor/tiny/plugins/kalturamedia"
        "local/kaltura"
        "local/kalturamediagallery"
        "local/mymedia"
        "mod/kalvidres"
        "mod/kalvidassign"
    )

    unzip -q "${plugin_zip_path}/kaltura.zip" -d "$plugin_unzip_path"

    installed_dirs=0
    for dir in "${kaltura_dirs[@]}"; do
        if [ -d "${moodle_path}/${dir}" ]; then
            ((installed_dirs++))
        fi
    done

    current_state=error
    if [ "$installed_dirs" -eq 0 ]; then
        current_state=false
    elif [ "$installed_dirs" -eq "${#kaltura_dirs[@]}" ]; then
        current_state=true
    else
        info "Kaltura current state is: ${current_state}. Found ${installed_dirs}/${#kaltura_dirs[@]} dirs"
        error "Kaltura is partially installed. Can not continue from inconsistent state."

        exit 1
    fi

    info "Kaltura current state is: ${current_state}. Found ${installed_dirs}/${#kaltura_dirs[@]} dirs"

    for dir in "${kaltura_dirs[@]}"; do
        if [ ! -d "${moodle_path}/${dir}" ]; then mkdir -p "${moodle_path}/${dir}"; fi
        mv "${plugin_zip_path}/kaltura/${dir}/"* "${moodle_path}/${dir}"/
    done
}

main() {
    rm -f "$update_plugins_path"

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
        plugin_target_state="${parts[3]}"

        plugin_parent_path=$(dirname "$plugin_path")
        full_path="${moodle_path}/${plugin_path}"

        plugin_cur_state=false
        
        if [[ "$plugin_name" == "kaltura" ]]; then
            applyKalturaState "$plugin_target_state"
            continue
        fi

        if [ -d "$full_path" ]; then
            plugin_cur_state=true
        fi

        if [ "$plugin_target_state" = "$plugin_cur_state" ]; then
            continue
        fi

        if [ "$plugin_target_state" = true ]; then
            last_installed_plugin="$full_path"
            MODULE="dbp-plugins" info "Installing plugin ${plugin_name} (${plugin_fullname}) to path \"${plugin_path}\""
            install_plugin "$plugin_name" "$plugin_fullname" "$plugin_path"
            last_installed_plugin=""
            anychange=true

        elif [ "$plugin_target_state" = false ]; then
            MODULE="dbp-plugins" info "Uninstalling plugin ${plugin_name} (${plugin_fullname}) from path \"${plugin_path}\""
            uninstall_plugin "$plugin_fullname" "$plugin_path"
            anychange=true
        else
            MODULE="dbp-plugins" info 'Unexpected value for plugin_target_state: "%s". Expecting "true/false". Exiting...' "$plugin_target_state"
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