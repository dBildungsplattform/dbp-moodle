#!/bin/bash
if [[ $# -eq 0 ]]
then
	echo "No Moodle image Version supplied";
	exit 1
fi

INPUT_REGEX="(^[0-9]+\.[0-9]+\.[0-9]$)"
if [[ $1 =~ $INPUT_REGEX ]];
then
    echo "Correct input format";
else
	echo "Wrong Version Input Format, aborting process";
	exit 1;
fi

# checks if image version(new) is greater than current installed version
version_greater() {
	if [[ $1 = $2 ]]; then echo "Already up to date"; return 0;
	elif [[ $1 > $2 ]]; then echo "Current version is higher, unable to downgrade!"; return 0;
    elif [[ $1 < $2 ]]; then echo "Initializing Moodle $image_version ..."; return 1;
	else echo "Unexpected behaviour, exiting version check"; return 0; fi
}

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

echo "The new Moodle env var version is $APP_VERSION";

if version_greater "$installed_version" "$image_version";
then
echo "Skipping Upgrade process"; exit 0
#TODO end the script properly to launch the container successfully
else
    echo "=== Starting Update ==="

    echo "=== Enable Maintenance Mode ==="
    echo '<h1>Sorry, maintenance in progress</h1>' > /bitnami/moodledata/climaintenance.html

    echo "=== Turn off liveness and readiness probe ==="
    helm upgrade --reuse-values --set livenessProbe.enabled=false --set readinessProbe.enabled=false moodle  bitnami/moodle --version {{ moodle_chart_version }} --namespace {{ moodle_namespace }}

    echo "=== Taking a Backup ==="
    if [ -d "/bitnami/moodledata/moodle-backup" ]; then
        rm -r /bitnami/moodledata/moodle-backup
    fi
    mkdir -p /bitnami/moodledata/moodle-backup
    cp -rp /bitnami/moodle/* /bitnami/moodledata/moodle-backup

    # TODO include correct way for Plugins
    curl {{ moodle_update_url }} -o /tmp/moodle.tgz

    echo "=== Download complete ==="
    if [ -d "/bitnami/moodledata/updated-moodle" ]; then
        rm -rf /bitnami/moodledata/updated-moodle
    fi
    mkdir /bitnami/moodledata/updated-moodle

    tar -xzf /tmp/moodle.tgz -C /bitnami/moodledata/updated-moodle --strip 1
    #Possible Breakpoint to check if the download works until here
    # rm -r /bitnami/moodle/*
    # cp -r /bitnami/moodledata/updated-moodle/* /bitnami/moodle/
    # cp /bitnami/moodledata/moodle-backup/config.php /bitnami/moodle/config.php
    # # plugin list - one could generate a diff and use that list
    # echo "=== Move plugins to updated installation ==="
    # for plugin in "etherpadlite hvp pdfannotator skype techproject zoom"
    # do
    #   cp -rp /bitnami/moodledata/moodle-backup/mod/$plugin /bitnami/moodle/mod/$plugin
    # done

    # echo "=== Setting Permissions right  ==="
    # chown root:root /bitnami/moodle
    # chown root:root /bitnami/moodledata
    # chown -R 1001:root /bitnami/moodledata/*
    # chown -R 1001:root /bitnami/moodle/*

    # echo "=== Turn liveness probe back on again ==="
    # helm upgrade --reuse-values --set livenessProbe.enabled=true --set readinessprobe.enable=true moodle bitnami/moodle --version {{ moodle_chart_version }} --namespace {{ moodle_namespace }}

    # echo "=== Disable Maintenance Mode ==="
    # rm  /bitnami/moodle-data/climaintenance.html
fi