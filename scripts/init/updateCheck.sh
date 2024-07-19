#!/bin/bash

set -o nounset

. /opt/bitnami/scripts/liblog.sh

moodle_path="/bitnami/moodle"

# data folders
new_moodle_unpack_path="/bitnami/moodledata/updated-moodle"
moodle_backup_path="/bitnami/moodledata/moodle-backup"

update_failed_path="/bitnami/moodledata/UpdateFailed"

indicateError() {
    touch "$update_failed_path"
}

cleanup() {
    rm -rf "$new_moodle_unpack_path"
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
        echo "1"
    else
        echo "-1"
    fi
}

get_installed_moodle_version() {
    if [ ! -f "${moodle_path}/version.php" ]; then
        MODULE="dbp-update" info "No installed Moodle version detected, seems to be fresh install"
        exit 0
    fi
    echo installed_ver="$(grep release "${moodle_path}/version.php" | grep -oP '\d+\.\d+\.\d+')"
}

create_backup() {
    if [ -d "$moodle_backup_path" ]; then
        rm -rf "$moodle_backup_path"
    fi
    mkdir -p "$moodle_backup_path"
    cp -rp "${moodle_path}/"* "$moodle_backup_path"
}

unpack_new_version() {
    if [ -d "$new_moodle_unpack_path" ]; then
        rm -rf "$new_moodle_unpack_path"
    fi
    mkdir "$new_moodle_unpack_path"
    tar -xzf "/moodle-${image_version}.tgz" -C "$new_moodle_unpack_path" --strip 1
}

main() {
    
    installed_version="$(get_installed_moodle_version)"
    image_version="$APP_VERSION"

    comp_result="$(compare_semver "$installed_version" "$image_version")"
    if [[ "$comp_result" == 0 ]]; then
        MODULE="dbp-update" info "Installed version ${installed_version} is same as image version ${image_version}."
        exit 0
    fi
    MODULE="dbp-update" info "Upgrading installed version ${installed_version} to ${image_version}"
    MODULE="dbp-update" info "Creating local backup"
    create_backup
    MODULE="dbp-update" info "Unpacking new moodle version"
    unpack_new_version

    # TODO test if i can leave this commented out since this script already runs as user 1001 it shouldnt be needed... maybe?
    # MODULE="dbp-update" info "Configure current user as owner of /bitnami/moodledata/"
    # chown -R 1001:root /bitnami/moodledata/*

    MODULE="dbp-update" info "Removing old Moodle (${installed_version})"
    rm -rf "${moodle_path:?}"/*
    MODULE="dbp-update" info "Installing new Moodle (${image_version})"
    cp -rp ${new_moodle_unpack_path}/* ${moodle_path}/
}

trap indicateError ERR
trap cleanup EXIT
main
