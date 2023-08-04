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

if [ -f /bitnami/moodledata/UpdateFailed ]; then
    echo "=== UpdateFailed file exists, please resolve the image problem manually ==="
    /opt/bitnami/scripts/moodle/entrypoint.sh "/opt/bitnami/scripts/moodle/run.sh"
fi

#Get the current installed version
installed_version="0.0.0"
if [ -f /bitnami/moodle/version.php ]; then
    LINE=$(grep release /bitnami/moodle/version.php)
    REGEX="release\s*=\s*'([0-9]+\.[0-9]+\.[0-9])"
    if [[ $LINE =~ $REGEX ]]; then
	    echo "Installed Moodle version:" ${BASH_REMATCH[1]}
        installed_version=${BASH_REMATCH[1]}
    fi
else
    #TODO What happens if there is no Moodle installed?
    echo "No installed Moodle Version detected"
    exit 0;
fi
#TODO for testing purposes only
installed_version="4.1.2"
echo "Simulated version: $installed_version"

#Is needed to check for success inside the container at the end
pre_update_version=installed_version;
echo "The new Moodle Image version is $APP_VERSION";

#Do version check
if version_greater "$installed_version" "$image_version";
then
echo "=== Skipping Update process and starting Moodle ===";
/opt/bitnami/scripts/moodle/entrypoint.sh "/opt/bitnami/scripts/moodle/run.sh"
else

    if ! [ -a /bitnami/moodledata/climaintenance.html ]; then
        echo "=== Enable Maintenance Mode ==="
        echo '<h1>Sorry, maintenance in progress</h1>' > /bitnami/moodledata/climaintenance.html
        sleep 5
        #The backup is only done once in the first run so we don't accidentally overwrite it
        echo "=== Taking a Backup ===" 
        if [ -d "/bitnami/moodledata/moodle-backup" ]; then
            rm -r /bitnami/moodledata/moodle-backup
        fi
        mkdir -p /bitnami/moodledata/moodle-backup
        cp -rp /bitnami/moodle/* /bitnami/moodledata/moodle-backup
    fi

    if ! [ -a /bitnami/moodledata/CliUpdate ]; then
        echo "=== Create required Files for Update ==="
        touch /bitnami/moodledata/CliUpdate
        sleep 20 #Ensure sufficient time for possible full update
    fi

    echo "=== Creating directory for new Version ==="
    if [ -d "/bitnami/moodledata/updated-moodle" ]; then
        rm -rf /bitnami/moodledata/updated-moodle
    fi
    mkdir /bitnami/moodledata/updated-moodle

    echo "=== Starting new Moodle Download of Version $APP_VERSION ==="

    #echo "=== Turn off liveness and readiness probe ==="
    #helm upgrade --reuse-values --set livenessProbe.enabled=false --set readinessProbe.enabled=false moodle  bitnami/moodle --namespace {{ moodle_namespace }}
    curl "https://packaging.moodle.org/stable401/moodle-4.1.4.tgz" -o /bitnami/moodledata/moodle.tgz && echo "=== Download done ==="
    tar -xzf /bitnami/moodledata/moodle.tgz -C /bitnami/moodledata/updated-moodle --strip 1 && echo "=== Unpacking done ==="
    #curl https://download.moodle.org/download.php/direct/stable401/moodle-4.1.2.tgz -L -o ./moodle.tgz
    sleep 5
    if ! [[ -a /bitnami/moodledata/moodle.tgz ]];then
        echo "Critical error, download link is not working"
        exit 0; #Hard abort here
    fi

    #Possible Breakpoint to check if the download works until here
    rm -rf /bitnami/moodle/*
    cp -r /bitnami/moodledata/updated-moodle/* /bitnami/moodle/ && echo "=== New moodle version copied to folder ==="
    rm -r /bitnami/moodledata/updated-moodle
    # cp /bitnami/moodledata/moodle-backup/config.php /bitnami/moodle/config.php
    # # plugin list - one could generate a diff and use that list
    # echo "=== Move plugins to updated installation ==="
    # for plugin in "etherpadlite hvp pdfannotator skype techproject zoom"
    # do
    #   cp -rp /bitnami/moodledata/moodle-backup/mod/$plugin /bitnami/moodle/mod/$plugin
    # done

    echo "=== Setting Permissions right  ==="
    chown root:root /bitnami/moodle
    chown root:root /bitnami/moodledata
    chown -R 1001:root /bitnami/moodledata/*
    chown -R 1001:root /bitnami/moodle/*

    # echo "=== Turn liveness probe back on again ==="
    #helm upgrade --reuse-values --set livenessProbe.enabled=true --set readinessprobe.enable=true moodle bitnami/moodle --version {{ moodle_chart_version }} --namespace {{ moodle_namespace }}

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
        exit 0;
    fi

    if [ $post_update_version == $image_version ]; then
        echo "=== Update to new Version $post_update_version successful ==="
        #Cleanup
        #echo "=== restoring old version ==="
        #rm -r /bitnami/moodle/*
        #cp -r /bitnami/moodledata/moodle-backup/* /bitnami/moodle/


        echo "=== Disable Maintenance Mode ==="
        rm -rf /bitnami/moodledata/updated-moodle
        #rm -r /bitnami/moodledata/moodle-backup
        rm /bitnami/moodledata/climaintenance.html
        rm /bitnami/moodledata/CliUpdate
        rm /bitnami/moodledata/moodle.tgz

        echo "=== Starting new Moodle version ==="
        /opt/bitnami/scripts/moodle/entrypoint.sh "/opt/bitnami/scripts/moodle/run.sh"
    elif [ $post_update_version == $pre_update_version ]; then
        echo "=== Update failed, old Version still installed ===" #Do we want to keep running until manual intervention?
        #exit 0;
        /opt/bitnami/scripts/moodle/entrypoint.sh "/opt/bitnami/scripts/moodle/run.sh"
    else
        echo "Something went wrong, please check the loggs"
    fi
    /opt/bitnami/scripts/moodle/entrypoint.sh "/opt/bitnami/scripts/moodle/run.sh"
fi