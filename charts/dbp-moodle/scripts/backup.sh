#!/bin/bash
set -e

health_file="/tmp/healthy"
backup_dir="/tmp/backup"

readiness_bckp="/tmp/readinessprobe.json"
liveness_bckp="/tmp/livenessprobe.json"
dummy_probe_patch=$(cat <<-EOF
	[{
		"op": "replace",
		"path": "/spec/template/spec/containers/0/readinessProbe",
		"value": {
			"exec": {
				"command": [
					"sh",
					"-c",
					"exit 0"
				]
			},
			"initialDelaySeconds": 5,
			"periodSeconds": 10
    	}
	},
	{
		"op": "replace",
		"path": "/spec/template/spec/containers/0/livenessProbe",
		"value": {
			"exec": {
				"command": [
					"sh",
					"-c",
					"exit 0"
				]
			},
			"initialDelaySeconds": 5,
			"periodSeconds": 10
    	}
	}]
	EOF
)

# Cleanup after finish only if not an update backup (normal backup has no CliUpdate file)
# If update backup: depending on exit code create the signal for the update helper job with success or failure
function clean_up() {
    exit_code=$?
    if ! [ -a /mountData/moodledata/CliUpdate ]; then
        echo "=== Starting cleanup ==="
        echo "=== Stopping maintenance mode ==="
        rm -f /mountData/moodledata/climaintenance.html

        echo "=== Turn on liveness and readiness probe ==="
        if [ -e "${readiness_bckp}" ] && [ -s "${readiness_bckp}" ] && [ -e "${liveness_bckp}" ] && [ -s "${liveness_bckp}" ] ; then
            # Careful, format the string with tabs only!
            restore_probe_patch=$(cat <<-EOF
				[{
					"op": "add",
					"path": "/spec/template/spec/containers/0/readinessProbe",
					"value": $(cat ${readiness_bckp})
				},
				{
					"op": "add",
					"path": "/spec/template/spec/containers/0/livenessProbe",
					"value": $(cat ${liveness_bckp})
				}]
				EOF
            )
            kubectl patch "deployment/${release_name}" -n "{{ .Release.Namespace }}" --type=json -p="$restore_probe_patch"
        else
            echo "Unable to turn on liveness and readiness probes. Either the readiness_bckp or the liveness_bckp does not exist or is empty."
        fi

        echo "=== Unsuspending moodle cronjob ==="
        kubectl patch cronjobs "{{ .Release.Name }}-moodlecronjob-{{ include "moodlecronjob.job_name" . }}" -n "{{ .Release.Namespace }}" -p '{"spec" : {"suspend" : false }}'
    elif [ $exit_code -eq 0 ]; then
        echo "=== Update backup was successful with exit code $exit_code ==="
        rm -f /mountData/moodledata/UpdateBackupFailure
        touch /mountData/moodledata/UpdateBackupSuccess
        exit $exit_code
    else
        echo "=== Update backup failed with exit code $exit_code ==="
        rm -f /mountData/moodledata/UpdateBackupSuccess
        touch /mountData/moodledata/UpdateBackupFailure
        rm -f "${health_file}"
        exit $exit_code
    fi
}

trap "clean_up" EXIT

# Create liveness probe file
touch "${health_file}"

# Deployment has "-moodle" appended if the Release.Name does not contain "moodle" 
release_name="{{ .Release.Name }}"
if [[ $release_name != "moodle" && $release_name != *"moodle"* ]]; then
    release_name="${release_name}-moodle"
fi

# Create destination dir if not exists
if [ ! -d "${backup_dir}" ]; then
    mkdir -p "${backup_dir}"
fi

# If the backup is done for the update it skips the preparation because the update helper already did this
if ! [ -a /mountData/moodledata/CliUpdate ]; then
    # Suspend the cronjob to avoid errors due to missing moodle
    echo "=== Suspending moodle cronjob ==="
    kubectl patch cronjobs "{{ .Release.Name }}-moodlecronjob-{{ include "moodlecronjob.job_name" . }}" -n "{{ .Release.Namespace }}" -p '{"spec" : {"suspend" : true }}'

    echo "=== Turn off liveness and readiness probe ==="
    kubectl get "deployment/${release_name}" -n "{{ .Release.Namespace }}" -o jsonpath="{.spec.template.spec.containers[0].readinessProbe}" > ${readiness_bckp}
    kubectl get "deployment/${release_name}" -n "{{ .Release.Namespace }}" -o jsonpath="{.spec.template.spec.containers[0].livenessProbe}" > ${liveness_bckp}
    kubectl patch "deployment/${release_name}" -n "{{ .Release.Namespace }}" --type=json -p="$dummy_probe_patch"

    kubectl rollout status "deployment/${release_name}" -n "{{ .Release.Namespace }}"

    # Wait for running jobs to finish to avoid errors
    echo "=== Waiting for jobs to finish ==="
    sleep 30
    
    echo "=== Starting maintenance mode ==="
    echo '<h1>Sorry, maintenance in progress</h1>' > /mountData/moodledata/climaintenance.html
fi

echo "=== Start backup ==="
date +%Y%m%d_%H%M%S%Z

cd "${backup_dir}"
# Get dump of db
echo "=== Start DB dump ==="
export DATE=$( date "+%Y-%m-%d" )

# shellcheck disable=all
{{ if or .Values.mariadb.enabled (eq .Values.moodle.externalDatabase.type "mariadb") }}
MYSQL_PWD="$DATABASE_PASSWORD" mysqldump -h "$DATABASE_HOST" -P "$DATABASE_PORT" -u "$DATABASE_USER" "$DATABASE_NAME" > "moodle_mariadb_dump_${DATE}.sql"
gzip "moodle_mariadb_dump_${DATE}.sql"
{{ else if or .Values.postgresql.enabled (eq .Values.moodle.externalDatabase.type "pgsql") }}
PGPASSWORD="$DATABASE_PASSWORD" pg_dump -h "$DATABASE_HOST" -p "$DATABASE_PORT" -U "$DATABASE_USER" "$DATABASE_NAME" > "moodle_postgresqldb_dump_${DATE}.sql"
gzip "moodle_postgresqldb_dump_${DATE}.sql"
{{ end }}

# Get moodle folder
echo "=== Start moodle directory backup ==="
tar -zcf moodle.tar.gz /mountData/moodle/

# Get moodledata folder
echo "=== Start moodledata directory backup ==="
tar \
    --exclude="/mountData/moodledata/cache" \
    --exclude="/mountData/moodledata/sessions" \
    --exclude="/mountData/moodledata/moodle-backup" \
    --exclude="/mountData/moodledata/CliUpdate" \
    --exclude="/mountData/moodledata/UpdateInProgress" \
    --exclude="/mountData/moodledata/UpdateFailed" \
    --exclude="/mountData/moodledata/PluginsFailed" \
    --exclude="/mountData/moodledata/climaintenance.html" \
    -zcf moodledata.tar.gz /mountData/moodledata/

echo "=== Start duply process ==="
cd /etc/duply/default
for cert in *.asc; do
    echo "=== Import key $cert ==="
    gpg --import --batch $cert
done
for fpr in $(gpg --batch --no-tty --command-fd 0 --list-keys --with-colons | awk -F: '/fpr:/ {print $10}' | sort -u); do
    echo "=== Trusts key $fpr ==="
    echo -e "5\ny\n" | gpg --batch --no-tty --command-fd 0 --expert --edit-key $fpr trust;
done
echo "=== Execute backup ==="
/usr/bin/duply default backup
/usr/bin/duply default status
cd /
rm -rf "${backup_dir}"
echo "=== Backup finished ==="
echo "=== Clean up old backups ==="
/usr/bin/duply default purge --force
date +%Y%m%d_%H%M%S%Z