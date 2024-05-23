#!/bin/bash
set -e

cur_image_version="$APP_VERSION"

# indicator files
update_plugins_path="/bitnami/moodledata/UpdatePlugins"
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

	if [[ "$current" = "$new" ]]; then echo "Already up to date"; return 0; fi

    greater_version="$(printf "%s\n%s" "$current" "$new" | sort --version-sort --reverse | head -n 1)"
    if [[ "$current" = "$greater_version" ]]; then echo "Current version is higher, unable to downgrade!"; return 0;
    elif [[ "$new" = "$greater_version" ]]; then echo "Initializing Moodle ${cur_image_version}..."; return 1;
    else echo "Unexpected behaviour, exiting version check"; return 0;
    fi
}

# Will remove the required files to restore functionality
cleanup() {
    echo "=== Deleting Moodle download folder ==="
    rm -rf "$new_version_data_path"
    rm -f /bitnami/moodledata/moodle.tgz
    if ! [ -f "$update_plugins_path" ]; then
        echo "=== Disabling maintenance mode and signaling that Update process is finished ==="
        rm -f "$maintenance_html_path"
    else
        echo "=== Plugin Update remaining, update DB and installing Plugins in new Pod ==="
    fi
    rm -f "$update_cli_path"
}

install_kaltura(){
    local kaltura_url="https://moodle.org/plugins/download.php/29483/Kaltura_Video_Package_moodle41_2022112803.zip"
    local kaltura_save_path="/bitnami/moodle/kaltura.zip"
    curl "$kaltura_url" --output "$kaltura_save_path"
    if [ ! -f "$kaltura_save_path" ]; then
        echo "=== Kaltura could not be installed, please check for correct Kaltura Url and try again ==="
        echo "Current kaltura url: ${kaltura_url}"
        return 1
    fi

    unzip kaltura.zip
    php /bitnami/moodle/admin/cli/upgrade.php --non-interactive
    rm -r "$kaltura_save_path"
    echo "=== Kaltura Plugin successfully installed ==="
}

update_plugins() {
    sleep 5
    rm -f "$update_plugins_path"
    if [[ $ENABLE_KALTURA == "True" ]]; then
        echo "=== Kaltura Flag enabled, installing Kaltura Plugin ==="
        install_kaltura
    fi

    # update moodle plugin list
    php /moosh/moosh.php plugin-list

    plugin_version="$image_major.$image_minor"
    nameRegEx="([0-9a-zA-Z_]*)+\#"
    pathRegEx="\#+([0-9a-zA-Z_/]*)"

    for plugin in $MOODLE_PLUGINS
    do
    # Get plugin name from the list <pluginName>#<pluginPath>
        plugin_path="NoValue"
        plugin_name="NoValue"
        if [[ $plugin =~ $pathRegEx ]]; then
            plugin_path=${BASH_REMATCH[1]}
        fi
        if [[ $plugin =~ $nameRegEx ]]; then
            plugin_name=${BASH_REMATCH[1]}
        fi
        printf '  Looking for "%s" (%s)... ' "$plugin_name" "$plugin_version"
        if [[ -d "$old_version_data_path"/$plugin_path ]]; then
            printf "Found!\n"
            printf "    Starting install..."
            if php /moosh/moosh.php plugin-install "$plugin_name"; then
                printf "Done\n"
            else
                printf "Failed!\n"
            fi
        else
            printf "Not found. Skipping\n"
        fi
    done
}

### Start of main ###
# Get Version number for download Link and reuse for later plugin update
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
    echo "=== UpdateFailed file exists, indicating failed Update! Please resolve the problem manually ==="
    echo "=== Removing maintenance and exiting update ==="

    rm -f "$maintenance_html_path"
    exit 1
fi

if [ -f "$update_plugins_path" ]; then
    echo "=== UpdatePlugins File found, starting Plugin installation ==="
    update_plugins
    echo "=== Finished UpdatePlugins, removing maintenance status and exiting update ==="
    rm -f "$maintenance_html_path"
    exit 0
fi

# Get the current installed version
installed_version="0.0.0"
if [ -f /bitnami/moodle/version.php ]; then
    LINE=$(grep release /bitnami/moodle/version.php)
    REGEX="release\s*=\s*'([0-9]+\.[0-9]*+\.[0-9]*)"
    if [[ $LINE =~ $REGEX ]]; then
	    echo "Installed Moodle version:" "${BASH_REMATCH[1]}"
        installed_version="${BASH_REMATCH[1]}"
    fi
else
    # Start new Moodle installation
    echo "No installed Moodle Version detected"
    echo "Starting fresh Bitnami installation..."
    /opt/bitnami/scripts/moodle/entrypoint.sh "/opt/bitnami/scripts/moodle/run.sh" &
    echo "=== Wait for 30s to copy config.php after Update start ==="
    sleep 30
    /bin/cp -p /moodleconfig/config.php /bitnami/moodle/config.php
    echo "=== Config.php copied to destination ==="
    /bin/cp /moodleconfig/php.ini /opt/bitnami/php/etc/conf.d/php.ini
    echo "=== php.ini copied to destination ==="
    wait
    exit 0
fi

# Is needed to check for success inside the container at the end
pre_update_version=$installed_version;
echo "The new Moodle Image version is $APP_VERSION";

# Do version check
if version_greater "$installed_version" "$cur_image_version"; then
    echo "=== Same Version, skipping Update process and exiting Update ==="
    exit 0
fi

# New version, create required Files
if ! [ -f "$maintenance_html_path" ]; then
    echo "=== Enabling maintenance mode ==="
    echo '<h1>Sorry, maintenance in progress</h1>' > "$maintenance_html_path"
    sleep 2
    # The backup is only done once in the first run so we don't accidentally overwrite it
    echo "=== Creating a backup ==="
    if [ -d "$old_version_data_path" ]; then
        rm -r "$old_version_data_path"
    fi
    mkdir -p "$old_version_data_path"
    cp -rp /bitnami/moodle/* "$old_version_data_path"
else
    echo "=== Maintenance Mode already active, skipping internal backup ==="
fi

# Wait for the Update Helper Job to disable the Probes and force a pod restart
if ! [ -f "$update_cli_path" ]; then
    echo "=== Create required CliUpdate indicator file ==="
    touch "$update_cli_path"
    sleep 600 # Wait for initial Pod termination by Update-Helper-Job
fi

# Start of the download step
echo "=== Creating directory for new version ==="
if [ -d "$new_version_data_path" ]; then
    rm -rf "$new_version_data_path"
fi
mkdir "$new_version_data_path"

echo "=== Starting download of new Moodle version $cur_image_version ==="
# Test if the download URL is available
download_url="https://packaging.moodle.org/stable${stable_version}/moodle-${cur_image_version}.tgz"
# https://download.moodle.org/download.php/direct/stable${stable_version}/moodle-${cur_image_version}.tgz alternative download url
echo "Download URL: ${download_url}"
url_response=$(curl --write-out '%{response_code}' --head --silent --output /dev/null "${download_url}")
if ! [ "$url_response" -eq 200 ]; then
    echo "=== Critical error, download link is not working, abort update process. Falling back to old version ==="
    touch "$update_failed_path"
    rm "$maintenance_html_path"
    rm "$update_cli_path" && sleep 2
    exit 1
else
    curl "$download_url" -o /bitnami/moodledata/moodle.tgz && echo "=== Download done ==="
    tar -xzf /bitnami/moodledata/moodle.tgz -C "$new_version_data_path" --strip 1 && echo "=== Unpacking done ==="
fi
sleep 2

echo "=== Setting Permissions right  ==="
chown -R 1001:root /bitnami/moodledata/*

rm -rf /bitnami/moodle/* && echo "=== Old moodle deleted ==="
cp -rp "${new_version_data_path}/*" /bitnami/moodle/ && echo "=== New moodle version copied to folder ==="

# Checks for the Moodle Plugin List
if [[ -n $MOODLE_PLUGINS ]]; then
    echo "=== Creating UpdatePlugins to trigger Plugin Installation ==="
    touch "$update_plugins_path"
else
    echo "=== MOODLE_PLUGINS environment variable missing, skipping plugin copy step ==="
fi

# If success
# Get the new installed version
echo "=== Checking newly installed downloaded Moodle version ==="
post_update_version="0.0.0"
if [ -f /bitnami/moodle/version.php ]; then
    LINE=$(grep release /bitnami/moodle/version.php)
    REGEX="release\s*=\s*'([0-9]+\.[0-9]+\.[0-9])"
    if [[ $LINE =~ $REGEX ]]; then
        echo "New Installed Moodle version:" "${BASH_REMATCH[1]}"
        post_update_version=${BASH_REMATCH[1]}
    fi
else
    # If no moodle Version was found we fall back to previous version
    echo "=== Update failed, no Moodle Version detected. Falling back to old version ==="
    cp -rp /bitnami/moodledata/moodle-backup/* /bitnami/moodle/ && echo "=== Old moodle version restored to folder ==="
    touch "$update_failed_path"
    sleep 5
    exit 1
fi

if [ "$post_update_version" == "$cur_image_version" ]; then
    /bin/cp -p /moodleconfig/config.php /bitnami/moodle/config.php
    echo "=== Update to new Version $post_update_version successful. ==="
    echo "=== Starting cleanup ==="
    cleanup
    echo "=== Cleanup done, exiting update ==="
    exit 0
elif [ "$post_update_version" == "$pre_update_version" ]; then
    echo "=== Update failed, old Version still installed. ==="
    touch "$update_failed_path"
    echo "=== Starting cleanup ==="
    cleanup
    echo "=== Cleanup done, exiting update ==="
    sleep 10
    exit 1
else
    # Normally we should never end up here
    echo "=== Something went very wrong, please check the logs ==="
    echo "The installed Moodle version (${post_update_version}) does not equal the previous version (${pre_update_version}) or the image version (${cur_image_version})"
    touch "$update_failed_path"
    exit 1
fi
