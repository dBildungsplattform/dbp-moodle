#!/bin/bash
set -e

RED='\033[0;31m'
GRN='\033[0;32m'
NC='\033[0m' # No Color

cur_image_version="$APP_VERSION"

moodle_path="/bitnami/moodle"

# indicator files
update_failed_path="/bitnami/moodledata/UpdateFailed"
update_cli_path="/bitnami/moodledata/CliUpdate"
maintenance_html_path="/bitnami/moodledata/climaintenance.html"

# data folders
new_version_data_path="/bitnami/moodledata/updated-moodle"
old_version_data_path="/bitnami/moodledata/moodle-backup"

# checks if image version(new) is greater than current installed version
version_greater() {
    local current=$1
    local new=$2
    local greater_version

    if [[ "$current" = "$new" ]]; then printf "${GRN}Already up to date${NC}\n"; return 0; fi

    greater_version="$(printf "%s\n%s" "$current" "$new" | sort --version-sort --reverse | head -n 1)"
    if [[ "$current" = "$greater_version" ]]; then printf "${RED}Current version is higher, unable to downgrade!${NC}\n"; return 0;
    elif [[ "$new" = "$greater_version" ]]; then printf "Initializing Moodle ${cur_image_version}...\n"; return 1;
    else printf "${RED}Unexpected behaviour, exiting version check${NC}\n"; return 0;
    fi
}

# Will remove the required files to restore functionality
cleanup() {
    printf "=== Deleting Moodle download folder ===\n"
    rm -rf "$new_version_data_path"
    rm -f /bitnami/moodledata/moodle.tgz
}



### Start of main ###
# Get Version number for download link
major_regex="\s*([0-9])+\."
minor_regex="\.([0-9]*)\."
if [[ $cur_image_version =~ $major_regex ]]; then
    image_major=${BASH_REMATCH[1]}
fi
if [[ $cur_image_version =~ $minor_regex ]]; then
    image_minor=${BASH_REMATCH[1]}
fi
if [ ${#image_minor} -lt 2 ]; then
    two_digit_image_minor=$(printf "%02d" "$image_minor")
fi
stable_version="${image_major}${two_digit_image_minor}"

if [ -f "$update_failed_path" ]; then
    printf "===${RED} UpdateFailed file exists, indicating failed update! Please resolve the problem manually ${NC}===\n"
    printf "=== Removing maintenance and exiting update ===\n"

    rm -f "$maintenance_html_path"
    exit 1
fi

# Get the current installed version
installed_version="0.0.0"
if [ ! -f "${moodle_path}/version.php" ]; then
    printf "=== No installed Moodle version detected, exiting update ===\n"
    printf "Normal start of bitnami moodle after this will do a fresh install\n"
    exit 0
fi
LINE=$(grep release "${moodle_path}/version.php")
REGEX="release\s*=\s*'([0-9]+\.[0-9]*+\.[0-9]*)"
if [[ $LINE =~ $REGEX ]]; then
    printf "Installed Moodle version: %s\n" "${BASH_REMATCH[1]}"
    installed_version="${BASH_REMATCH[1]}"
fi

# Is needed to check for success inside the container at the end
pre_update_version="$installed_version"
printf "The new Moodle Image version is %s\n" "$APP_VERSION"

# Do version check
if version_greater "$installed_version" "$cur_image_version"; then
    printf "=== Same Version, skipping update process and exiting update ===\n"
    rm -f "/bitnami/moodledata/moodleUpdateCheck.log"
    exit 0
fi

# New version, create required Files
if ! [ -f "$maintenance_html_path" ]; then
    printf "=== Enabling maintenance mode ===\n"
    printf '<h1>Sorry, maintenance in progress</h1>\n' > "$maintenance_html_path"
    sleep 2
    # The backup is only done once in the first run so we don't accidentally overwrite it
    printf "=== Creating a backup ===\n"
    if [ -d "$old_version_data_path" ]; then
        rm -r "$old_version_data_path"
    fi
    mkdir -p "$old_version_data_path"
    cp -rp "${moodle_path}/"* "$old_version_data_path"
else
    printf "=== Maintenance Mode already active, skipping internal backup ===\n"
fi

# Wait for the Update Helper Job to disable the Probes and force a pod restart
if ! [ -f "$update_cli_path" ]; then
    printf "=== Create required CliUpdate indicator file ===\n"
    touch "$update_cli_path"
    printf "=== Wait for initial Pod termination by Update-Helper-Job ===\n"
    sleep 600
fi

# Start of the download step
printf "=== Creating directory for new version ===\n"
if [ -d "$new_version_data_path" ]; then
    rm -rf "$new_version_data_path"
fi
mkdir "$new_version_data_path"

printf "=== Downloading new Moodle version: %s ===\n" "$cur_image_version"
# Test if the download URL is available
download_url="https://packaging.moodle.org/stable${stable_version}/moodle-${cur_image_version}.tgz"
# https://download.moodle.org/download.php/direct/stable${stable_version}/moodle-${cur_image_version}.tgz alternative download url
printf "Download URL: %s\n" "$download_url"
url_response=$(curl --write-out '%{response_code}' --head --silent --output /dev/null "${download_url}")
if ! [ "$url_response" -eq 200 ]; then
    printf "===${RED} Critical error${NC}, download link is not working, abort update process. Falling back to old version ===\n"
    touch "$update_failed_path"
    rm "$maintenance_html_path"
    rm "$update_cli_path" && sleep 2
    exit 1
else
    printf "=== Downloading new moodle ===\n"
    curl "$download_url" -o /bitnami/moodledata/moodle.tgz
    printf "Unpacking it to %s\n" "$new_version_data_path"
    tar -xzf /bitnami/moodledata/moodle.tgz -C "$new_version_data_path" --strip 1
fi
sleep 2 #TODO ???

printf "=== Setting current user as owner for moodledata  ===\n"
chown -R 1001:root /bitnami/moodledata/*
printf "=== Deleting old Moodle ===\n"
rm -rf "${moodle_path:?}"/*
printf "=== Copying new Moodle to folder ===\n"
cp -rp ${new_version_data_path}/* ${moodle_path}/

# If success
# Get the new installed version
printf "=== Checking newly installed downloaded Moodle version ===\n"
post_update_version="0.0.0"
if [ -f "${moodle_path}/version.php" ]; then
    LINE=$(grep release "${moodle_path}/version.php")
    REGEX="release\s*=\s*'([0-9]+\.[0-9]+\.[0-9]+)"
    if [[ $LINE =~ $REGEX ]]; then
        printf "New Installed Moodle version: %s\n" "${BASH_REMATCH[1]}"
        post_update_version=${BASH_REMATCH[1]}
    fi
else
    # If no moodle Version was found we fall back to previous version
    printf "===${RED} Update failed${NC}, no Moodle version detected. Falling back to old version ===\n"
    cp -rp /bitnami/moodledata/moodle-backup/* "${moodle_path}/" && printf "=== Old moodle version restored to folder ===\n"
    touch "$update_failed_path"
    sleep 5
    exit 1
fi

if [ "$post_update_version" == "$cur_image_version" ]; then
    /bin/cp -p /moodleconfig/config.php "${moodle_path}/config.php"
    printf "===${GRN} Update to new version %s successful! ${NC}===\n" "$post_update_version"
    printf "=== Starting cleanup ===\n"
    cleanup
    printf "===${GRN} Cleanup done${NC}, exiting update ===\n"
    exit 0
elif [ "$post_update_version" == "$pre_update_version" ]; then
    printf "===${RED} Update failed, old version still installed. ${NC}===\n"
    touch "$update_failed_path"
    printf "=== Starting cleanup ===\n"
    cleanup
    printf "===${GRN} Cleanup done${NC}, exiting update ===\n"
    sleep 10
    exit 1
else
    # Normally we should never end up here
    printf "===${RED} Something went very wrong, please check the logs ${NC}===\n"
    printf "The installed Moodle version (%s) does not equal the previous version (%s) or the image version (%s)\n" "$post_update_version" "$pre_update_version" "$cur_image_version"
    touch "$update_failed_path"
    exit 1
fi
