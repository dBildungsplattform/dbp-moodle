#!/bin/bash
set -e
image_version="$APP_VERSION"

# checks if image version(new) is greater than current installed version
version_greater() {
    current=$1
    new=$2
	if [[ $current = $new ]]; then echo "Already up to date"; return 0;
	elif [[ $current > $new ]]; then echo "Current version is higher, unable to downgrade!"; return 0;
    elif [[ $current < $new ]]; then echo "Initializing Moodle $image_version ..."; return 1;
	else echo "Unexpected behaviour, exiting version check"; return 0;
    fi
}

#Will remove the required files to restore functionality
cleanup() {
    echo "=== Deleting Moodle download folder ==="
    rm -rf /bitnami/moodledata/updated-moodle
    rm -f /bitnami/moodledata/moodle.tgz
    if ! [ -a /bitnami/moodledata/UpdatePlugins ];
    then
        echo "=== Disabling maintenance mode and signaling that Update process is finished ==="
        rm -f /bitnami/moodledata/climaintenance.html
    else
        echo "=== Plugin Update remaining, update DB and installing Plugins in new Pod ==="
    fi
    rm -f /bitnami/moodledata/CliUpdate
}

#Starts the currently installed Moodle application
start_moodle(){
    /bin/cp -p /moodleconfig/config.php /bitnami/moodle/config.php
    cat /moodleconfig/php.ini >> /opt/bitnami/php/etc/conf.d/php.ini
    #Append the redis config on the php.ini
    /opt/bitnami/scripts/moodle/entrypoint.sh "/opt/bitnami/scripts/moodle/run.sh"
    exit 1
}

if [ -f /bitnami/moodledata/UpdateFailed ]; then
    echo "=== UpdateFailed file exists, please resolve the problem manually ==="
    rm -f /bitnami/moodledata/climaintenance.html
    start_moodle
fi

if [ -f /bitnami/moodledata/UpdatePlugins ]; then
    echo "=== UpdatePlugins File found, starting Plugin installation ==="
    sleep 5
    rm -f /bitnami/moodledata/UpdatePlugins
    if [[ $ENABLE_KALTURA == "True" ]]; then
        echo "=== Kaltura Flag found and set to True, installing Kaltura Plugin ==="
        cd /bitnami/moodle
        curl https://moodle.org/plugins/download.php/29483/Kaltura_Video_Package_moodle41_2022112803.zip --output kaltura.zip
        if [ -a /bitnami/moodle/kaltura.zip ]; then
            unzip kaltura.zip
            cd /bitnami/moodle/admin/cli
            php upgrade.php --non-interactive
            cd /
            rm -r /bitnami/moodle/kaltura.zip
            echo "=== Kaltura Plugin successfully installed ==="
        else
            echo "=== Kaltura could not be installed, please check for correct Kaltura Url and try again ==="
        fi
    fi
    major_regex="\s*([0-9])+\."
    minor_regex="\.([0-9]*)\."
    if [[ $image_version =~ $major_regex ]]; then
            image_major=${BASH_REMATCH[1]}
    fi
    if [[ $image_version =~ $minor_regex ]]; then
            image_minor=${BASH_REMATCH[1]}
    fi
    plugin_version="$image_major.$image_minor"
    nameRegEx="([0-9a-zA-Z_]*)+\#"
    pathRegEx="\#+([0-9a-zA-Z_/]*)"
    cd /bitnami/moodle/
    php /moosh/moosh/moosh.php plugin-list
    for plugin in $MOODLE_PLUGINS
    do
    #Get plugin name from the list <pluginName>#<pluginPath>
        plugin_path="NoValue"
        plugin_name="NoValue"
        if [[ $plugin =~ $pathRegEx ]];
        then
            plugin_path=${BASH_REMATCH[1]}
        fi
        if [[ $plugin =~ $nameRegEx ]];
        then
            plugin_name=${BASH_REMATCH[1]}
        fi
        echo "=== Looking for Plugin: $plugin_name ==="
        if [[ -d /bitnami/moodledata/moodle-backup/$plugin_path ]]
        then
            php /moosh/moosh/moosh.php plugin-install $plugin_name
            echo "Plugin $plugin_name for Moodle Version $plugin_version installed"
        fi
    done
    cd /
    rm -f /bitnami/moodledata/climaintenance.html
    start_moodle
fi

#Get the current installed version
installed_version="0.0.0"
if [ -f /bitnami/moodle/version.php ]; then
    LINE=$(grep release /bitnami/moodle/version.php)
    REGEX="release\s*=\s*'([0-9]+\.[0-9]*+\.[0-9]*)"
    if [[ $LINE =~ $REGEX ]]; then
	    echo "Installed Moodle version:" ${BASH_REMATCH[1]}
        installed_version=${BASH_REMATCH[1]}
    fi
else
    #Start new Moodle installation
    echo "No installed Moodle Version detected"
    echo "Fresh Bitnami installation..."
    /opt/bitnami/scripts/moodle/entrypoint.sh "/opt/bitnami/scripts/moodle/run.sh" &
    echo "=== Wait for 30s to copy config.php after Update start ==="
    sleep 30
    /bin/cp -p /moodleconfig/config.php /bitnami/moodle/config.php
    echo "=== Config.php copied to destination ==="
    #Append the redis config on the php.ini
    /opt/bitnami/scripts/moodle/entrypoint.sh "/opt/bitnami/scripts/moodle/run.sh"
    echo "=== php.ini for redis updated ==="
    wait
    exit 1
fi

#Is needed to check for success inside the container at the end
pre_update_version=$installed_version;
echo "The new Moodle Image version is $APP_VERSION";

#Do version check
if version_greater "$installed_version" "$image_version";
then
echo "=== Same Version, skipping Update process and starting Moodle ===";
start_moodle
else
    #New version, create required Files
    if ! [ -a /bitnami/moodledata/climaintenance.html ]; then
        echo "=== Enable Maintenance Mode ==="
        echo '<h1>Sorry, maintenance in progress</h1>' > /bitnami/moodledata/climaintenance.html
        sleep 2
        #The backup is only done once in the first run so we don't accidentally overwrite it
        echo "=== Taking a Backup ===" 
        if [ -d "/bitnami/moodledata/moodle-backup" ]; then
            rm -r /bitnami/moodledata/moodle-backup
        fi
        mkdir -p /bitnami/moodledata/moodle-backup
        cp -rp /bitnami/moodle/* /bitnami/moodledata/moodle-backup
    else
        echo "=== Maintenance Mode already active, skipping internal backup ==="
    fi

    #Wait for the Update Helper Job to disable the Probes and force a pod restart
    if ! [ -a /bitnami/moodledata/CliUpdate ]; then
        echo "=== Create required Files for Update ==="
        touch /bitnami/moodledata/CliUpdate
        sleep 600 #Wait for initial Pod termination by Update-Helper-Job
    fi

    #Start of the download step
    echo "=== Creating directory for new Version ==="
    if [ -d "/bitnami/moodledata/updated-moodle" ]; then
        rm -rf /bitnami/moodledata/updated-moodle
    fi
    mkdir /bitnami/moodledata/updated-moodle

    echo "=== Starting new Moodle Download of Version $image_version ==="

    #Get Version number for download Link and reuse for later Plugin update
    major_regex="\s*([0-9])+\."
    minor_regex="\.([0-9]*)\."
    if [[ $image_version =~ $major_regex ]]; then
            image_major=${BASH_REMATCH[1]}
    fi
    if [[ $image_version =~ $minor_regex ]]; then
            image_minor=${BASH_REMATCH[1]}
    fi
    if [ ${#image_minor} -lt 2 ];
    then two_digit_image_minor=$(printf "%02d" $image_minor)
    fi
    stable_version=$image_major$two_digit_image_minor

    #Get Version Number for Plugin update
    if [[ $installed_version =~ $major_regex ]]; then
            installed_major=${BASH_REMATCH[1]}
    fi
    if [[ $installed_version =~ $minor_regex ]]; then
            installed_minor=${BASH_REMATCH[1]}
    fi

    #Test if the download URL is available
    download_url="https://packaging.moodle.org/stable${stable_version}/moodle-${image_version}.tgz"
    #https://download.moodle.org/download.php/direct/stable${stable_version}/moodle-${image_version}.tgz alternative download url
    echo "Download URL: ${download_url}"
    url_response=$(curl --write-out '%{response_code}' --head --silent --output /dev/null ${download_url})
    if ! [ $url_response -eq 200 ];
    then echo "=== Critical error, download link is not working, abort update process ==="
        touch /bitnami/moodledata/UpdateFailed
        rm /bitnami/moodledata/climaintenance.html
        rm /bitnami/moodledata/CliUpdate && sleep 2
        start_moodle
    else
        curl $download_url -o /bitnami/moodledata/moodle.tgz && echo "=== Download done ==="
        tar -xzf /bitnami/moodledata/moodle.tgz -C /bitnami/moodledata/updated-moodle --strip 1 && echo "=== Unpacking done ==="
    fi
    sleep 2

    echo "=== Setting Permissions right  ==="
    chown -R 1001:root /bitnami/moodledata/*

    rm -rf /bitnami/moodle/* && echo "=== Old moodle deleted ==="
    cp -rp /bitnami/moodledata/updated-moodle/* /bitnami/moodle/ && echo "=== New moodle version copied to folder ==="

    #Checks for the Moodle Plugin List 
    if [[ ! -z $MOODLE_PLUGINS ]]
    then
        echo "=== Creating UpdatePlugins to trigger Plugin Installation ==="
        touch /bitnami/moodledata/UpdatePlugins
    else
        echo "=== MOODLE_PLUGINS environment variable missing, skipping plugin copy step ==="
    fi

    #If success
    #Get the new installed version
    echo "=== Checking newly installed downloaded Moodle version ==="
    post_update_version="0.0.0"
    if [ -f /bitnami/moodle/version.php ]; then
        LINE=$(grep release /bitnami/moodle/version.php)
        REGEX="release\s*=\s*'([0-9]+\.[0-9]+\.[0-9])"
        if [[ $LINE =~ $REGEX ]]; then
            echo "New Installed Moodle version:" ${BASH_REMATCH[1]}
            post_update_version=${BASH_REMATCH[1]}
        fi
    else
        #If no moodle Version was found we fall back to previous version
        echo "=== Update failed, no Moodle Version detected fallback to old Version ==="
        cp -rp /bitnami/moodledata/moodle-backup/* /bitnami/moodle/ && echo "=== Old moodle version restored to folder ==="
        touch /bitnami/moodledata/UpdateFailed
        sleep 5
        start_moodle
    fi

    if [ $post_update_version == $image_version ]; then
        /bin/cp -p /moodleconfig/config.php /bitnami/moodle/config.php
        echo "=== Update to new Version $post_update_version successful ==="
        cleanup
        echo "=== Starting new Moodle version ==="
        start_moodle
    elif [ $post_update_version == $pre_update_version ]; then
        echo "=== Update failed, old Version still installed ==="
        touch /bitnami/moodledata/UpdateFailed
        cleanup
        sleep 10
        start_moodle
    else
        #Normally we should never end up here
        echo "=== Something went wrong, please check the logs(The installed Moodle version does not equal the previous version or the image version) ==="
        touch /bitnami/moodledata/UpdateFailed
        exit 1;
    fi
fi