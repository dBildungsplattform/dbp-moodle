#!/bin/bash
set -e
#image_version="$APP_VERSION"
image_version="4.1.4" #Provoke update
# checks if image version(new) is greater than current installed version
version_greater() {
	if [[ $1 = $2 ]]; then echo "Already up to date"; return 0;
	elif [[ $1 > $2 ]]; then echo "Current version is higher, unable to downgrade!"; return 0;
    elif [[ $1 < $2 ]]; then echo "Initializing Moodle $image_version ..."; return 1;
	else echo "Unexpected behaviour, exiting version check"; return 0; fi
}

#Will remove the required files to restore functionality
cleanup() {
    echo "=== Deleting Moodle download folder ==="
    rm -rf /bitnami/moodledata/updated-moodle
    #echo "=== Deleting Moodle internal Backup folder ==="
    #rm -rf /bitnami/moodledata/moodle-backup
    echo "=== Disabling maintenance mode and signaling that Update process is finished ==="
    rm -f /bitnami/moodledata/moodle.tgz
    rm -f /bitnami/moodledata/climaintenance.html
    rm -f /bitnami/moodledata/CliUpdate
}

#Starts the currently installed Moodle application
start_moodle(){
    /opt/bitnami/scripts/moodle/entrypoint.sh "/opt/bitnami/scripts/moodle/run.sh"
    exit 1
}

if [ -f /bitnami/moodledata/UpdateFailed ]; then
    echo "=== UpdateFailed file exists, please resolve the problem manually ==="
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
    #TODO What happens if there is no Moodle installed?
    echo "No installed Moodle Version detected"
    echo "Fresh Bitnami installation..."
    start_moodle
fi
#TODO for testing purposes only
installed_version="4.1.2"
echo "Simulated version: $installed_version"

#Is needed to check for success inside the container at the end
pre_update_version=$installed_version;
echo "The new Moodle Image version is $APP_VERSION";

#Do version check
if version_greater "$installed_version" "$image_version";
then
echo "=== Same Version, skipping Update process and starting Moodle ===";
/opt/bitnami/scripts/moodle/entrypoint.sh "/opt/bitnami/scripts/moodle/run.sh"
else
    #New version, create required Files
    if ! [ -a /bitnami/moodledata/climaintenance.html ]; then
        echo "=== Enable Maintenance Mode ==="
        echo '<h1>Sorry, maintenance in progress</h1>' > /bitnami/moodledata/climaintenance.html
        sleep 2
        #TODO Clear cache and Sessions
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
        sleep 40 #Ensure sufficient time for possible full backup
    fi

    #Start of the download step
    echo "=== Creating directory for new Version ==="
    if [ -d "/bitnami/moodledata/updated-moodle" ]; then
        rm -rf /bitnami/moodledata/updated-moodle
    fi
    mkdir /bitnami/moodledata/updated-moodle

    echo "=== Starting new Moodle Download of Version $image_version ==="

    #Get Version number for download Link
    major_regex="\s*([0-9])+\."
    minor_regex="\.([0-9]*)\."
    if [[ $image_version =~ $major_regex ]]; then
            major=${BASH_REMATCH[1]}
    fi
    if [[ $image_version =~ $minor_regex ]]; then
            minor=${BASH_REMATCH[1]}
    fi
    if [ ${#minor} -lt 2 ];
    then minor=$(printf "%02d" $minor)
    fi
    stable_version=$major$minor

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
        #exit 1; #Hard abort here
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
    # cp /bitnami/moodledata/moodle-backup/config.php /bitnami/moodle/config.php
    # # plugin list - one could generate a diff and use that list
    # echo "=== Move plugins to updated installation ==="
    # for plugin in "etherpadlite hvp pdfannotator skype techproject zoom"
    # do
    #   cp -rp /bitnami/moodledata/moodle-backup/mod/$plugin /bitnami/moodle/mod/$plugin
    # done

    #If success
    #Get the new installed version
    echo "=== Checking downloaded Moodle version ==="
    post_update_version="0.0.0"
    if [ -f /bitnami/moodle/version.php ]; then
    #if [ -f /bitnami/moodledata/updated-moodle/version.php ]; then
        LINE=$(grep release /bitnami/moodle/version.php)
        REGEX="release\s*=\s*'([0-9]+\.[0-9]+\.[0-9])"
        if [[ $LINE =~ $REGEX ]]; then
            echo "Installed Moodle version:" ${BASH_REMATCH[1]}
            post_update_version=${BASH_REMATCH[1]}
        fi
    else
        #TODO What happens if there is no Moodle installed?
        echo "=== Update failed, no Moodle Version detected ==="
        exit 1;
    fi

    if [ $post_update_version == $image_version ]; then
        echo "=== Update to new Version $post_update_version successful ==="
        cleanup
        echo "=== Starting new Moodle version ==="
        start_moodle
    elif [ $post_update_version == $pre_update_version ]; then
        echo "=== Update failed, old Version still installed ===" #Do we want to keep running until manual intervention?
        touch /bitnami/moodledata/UpdateFailed
        cleanup
        #exit 1;
        start_moodle
    else
        #TODO check for possible outcomes here
        echo "Something went wrong, please check the logs"
        touch /bitnami/moodledata/UpdateFailed
        exit 1;
    fi
fi