#!/bin/bash
# This script will be called by the entrypoint.sh on docker image startup and acts as a way to keep our plugins up to date.
# If the PluginsFailed and UpdateFailed signal files do not exist, it will move the plugins from the image to the moodle installation.
# This will ensure that always the most up to date plugins from the image will be used.
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

cleanup() {
    if [[ -n "$plugin_unzip_path" ]]; then
        rm -rf "$plugin_unzip_path"
    fi
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

get_plugin_version() {
    local plugin_path="$1"
    if [ ! -f "$plugin_path/version.php" ]; then
        return
    fi
    grep -Po '\$plugin->version\s*=\s*\K\d+' "${plugin_path}/version.php" | head -n 1

}

main() {
    rm -f "$update_plugins_path"

    if [ -d "$plugin_unzip_path" ]; then
        rm -rf "$plugin_unzip_path"
    fi
    mkdir "$plugin_unzip_path"

    anychange=false

    # Update or uninstall third party plugins, depending on the current and target state.
    for plugin in $MOODLE_PLUGINS; do
        IFS=':' read -r -a parts <<< "$plugin"
        plugin_name="${parts[0]}"
        plugin_fullname="${parts[1]}"
        plugin_path="${parts[2]}"
        plugin_target_state="${parts[3]}"

        plugin_parent_path=$(dirname "$plugin_path")
        full_path="${moodle_path}/${plugin_path}"

        plugin_cur_state=false

        if [ -d "$full_path" ]; then
            plugin_cur_state=true
        fi

        if [ "$plugin_target_state" = "$plugin_cur_state" ]; then
            # Check if plugin update is required due to newer version in new image
            if [ "$plugin_target_state" = true ]; then
                installed_plugin_version="$(get_plugin_version $full_path)"
                unzip -q "${plugin_zip_path}/${plugin_fullname}.zip" -d "$plugin_unzip_path"
                new_plugin_path="${plugin_unzip_path}/${plugin_name}"
                new_plugin_version="$(get_plugin_version $new_plugin_path)"
                # Plugin version comparison
                if [ "$new_plugin_version" -gt "$installed_plugin_version" ]; then
                    MODULE="dbp-plugins" info "Plugin ${plugin_name} version changed (installed version: ${installed_plugin_version}, new version: ${new_plugin_version}). Updating..."
                    rm -rf "${moodle_path:?}/${plugin_path:?}"
                    mv "${plugin_unzip_path}${plugin_name}" "${moodle_path}/${plugin_parent_path:?}/"
                    new_installed_plugin_version="$(get_plugin_version $full_path)"
                    MODULE="dbp-plugins" info "New installed plugin ${plugin_name} version: ${new_installed_plugin_version}"
                    anychange=true
                else
                    MODULE="dbp-plugins" info "No version change of plugin ${plugin_name} detected or required."
                fi
            fi
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
            MODULE="dbp-plugins" error "Unexpected value for plugin_target_state: \"$plugin_target_state\". Expecting \"true/false\". Exiting..."
            exit 1
        fi
    done

    # Uninstall certain standard plugins which are not in use. Whether any plugins are uninstall depends on the content of moodle-plugins config map.
    # Currently not in use but can just be commented in when required.
    # for plugin in $MOODLE_PLUGINS_SYS_UNINSTALL; do
    #     IFS=':' read -r -a parts <<< "$plugin"
    #     plugin_name="${parts[0]}"
    #     plugin_fullname="${parts[1]}"
    #     plugin_path="${parts[2]}"
    #     plugin_uninstall="${parts[3]}"

    #     if [ "$plugin_uninstall" = true ]; then
    #         uninstall_plugin "$plugin_fullname" "$plugin_path"
    #         MODULE="dbp-plugins" info "Uninstalling plugin ${plugin_name} (${plugin_fullname}) from path \"${plugin_path}\""
    #         anychange=true
    #     fi
    # done
    
    
    if [ "$anychange" = true ]; then
        upgrade_if_pending
        php "${moodle_path}/admin/cli/uninstall_plugins.php" --purge-missing --run
        php "${moodle_path}/admin/cli/purge_caches.php"
    else
        MODULE="dbp-plugins" info 'No plugin state change detected.'
    fi

    rm -f "$maintenance_html_path" # TODO move this to entrypoint probably
}

trap cleanup_failed_install ERR
trap cleanup EXIT
main