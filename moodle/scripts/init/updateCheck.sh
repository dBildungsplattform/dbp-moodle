#!/bin/bash

set -o nounset

. /opt/bitnami/scripts/liblog.sh

moodle_path="/bitnami/moodle"

# data folders
moodle_backup_path="/bitnami/moodledata/moodle-backup"

onErrorRestoreBackup() {
    mv "${moodle_path}" "${moodle_path}-failed"
    cp -rp "${moodle_backup_path}" "${moodle_path}"
}

# return 0 if equal, -1 if $1 > $2 and 1 if $1 < $2
compare_semver() {
    local v1="$1"
    local v2="$2"

    v1=$(printf '%03d%03d%03d' ${1//./ })
    v2=$(printf '%03d%03d%03d' ${2//./ })

    if [[ "$v1" == "$v2" ]]; then
        echo "0"
    elif [[ "$v1" > "$v2" ]]; then
        echo "-1"
    elif [[ "$v1" < "$v2" ]]; then
        echo "1"
    fi
}

get_installed_moodle_version() {
    if [ ! -f "${moodle_path}/version.php" ]; then
        return
    fi
    grep release "${moodle_path}/version.php" | grep -oP '\d+\.\d+\.\d+'
}

create_backup() {
    if [ -d "$moodle_backup_path" ]; then
        rm -rf "$moodle_backup_path"
    fi
    mkdir -p "$moodle_backup_path"
    cp -rp "${moodle_path}/"* "$moodle_backup_path"
}

install_new_version() {
    local image_version="$1"
    MODULE="dbp-update" info "Installing new Moodle (${image_version})"
    mkdir -p "$moodle_path"
    tar --strip-components=1 -xzf "/moodle-${image_version}.tgz" -C "$moodle_path"
}

main() {
    
    installed_version="$(get_installed_moodle_version)"
    image_version="$APP_VERSION"

    if [[ -z "$installed_version" ]]; then
        MODULE="dbp-update" info "No installed Moodle version detected, continuing with Bitnami fresh install"
        exit 0
    fi
    comp_result="$(compare_semver "$installed_version" "$image_version")"
    
    if [[ "$comp_result" == 0 ]]; then
        MODULE="dbp-update" info "Installed version ${installed_version} is same as image version ${image_version}"
        exit 0
    fi
    
    if [[ "$comp_result" == 1 ]]; then
        MODULE="dbp-update" info "Starting update of installed version ${installed_version} to ${image_version}"
    else
        MODULE="dbp-update" error "Preventing attempted downgrade of installed version ${installed_version} to ${image_version}!"
        MODULE="dbp-update" error "Exiting update..."
        exit 1
    fi
    MODULE="dbp-update" info "Creating local backup"
    create_backup
    MODULE="dbp-update" info "Unpacking new moodle version"

    if [[ -n "$installed_version" ]]; then
        MODULE="dbp-update" info "Removing old Moodle (${installed_version})"
    fi
    rm -rf "${moodle_path:?}"/*
    install_new_version "$image_version"
}

trap onErrorRestoreBackup ERR
main
