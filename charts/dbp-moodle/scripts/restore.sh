#!/bin/bash
set -e

function clean_up() {
    exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "=== Finished restore process ==="
        exit $exit_code
    else
        echo "=== An error occurred. Deleting health file: ${health_file} ==="
        rm -f "${health_file}"
        exit $exit_code
    fi
}

trap "clean_up" EXIT

health_file="/tmp/healthy"

# Create liveness probe file
touch "${health_file}"

{{ if and .Values.dbpMoodle.backup.s3_certificate_path .Values.dbpMoodle.backup.s3_certificate_key }}
printf "Appendending custom certificate (%s/%s) to /etc/ssl/certs/ca-certificates.crt\n" "{{ .Values.dbpMoodle.backup.s3_certificate_path }}" "{{ .Values.dbpMoodle.backup.s3_certificate_key }}"
cat "{{ .Values.dbpMoodle.backup.s3_certificate_path }}/{{ .Values.dbpMoodle.backup.s3_certificate_key }}" >> /etc/ssl/certs/ca-certificates.crt
{{ end }}

# Deployment has "-moodle" appended if the Release.Name does not contain "moodle" 
deployment_name="{{ .Release.Name }}"
if [[ "$deployment_name" != "moodle" && "$deployment_name" != *"moodle"* ]]; then
    deployment_name="${deployment_name}-moodle"
fi

# Get current replicas and scale down deployment
replicas=$(kubectl get "deployment/${deployment_name}" -n {{ .Release.Namespace }} -o=jsonpath='{.status.replicas}')
echo "=== Current replicas detected: $replicas ==="
if [ -z "$replicas" ] || [ "$replicas" -eq 0 ]; then 
    replicas=1
fi
echo "=== Scale moodle deployment to 0 replicas for restore operation ==="
kubectl scale "deployment/${deployment_name}" --replicas=0 -n {{ .Release.Namespace }}
echo "=== After restore operation is completed will scale back to: $replicas replicas ==="

# Restore
cd /etc/duply/default
for cert in *.asc; do
    echo "=== Import key $cert ==="
    gpg --import --batch $cert
done
for fpr in $(gpg --batch --no-tty --command-fd 0 --list-keys --with-colons  | awk -F: '/fpr:/ {print $10}' | sort -u); do
    echo "=== Trusts key $fpr ==="
    echo -e "5\ny\n" |  gpg --batch --no-tty --command-fd 0 --expert --edit-key $fpr trust;
done

cd /bitnami/
echo "=== Download backup ==="
duply default restore Full
echo "=== Clear PVC ==="
rm -rf /bitnami/moodle/*
rm -rf /bitnami/moodle/.[!.]*
rm -rf /bitnami/moodledata/*
rm -rf /bitnami/moodle/.[!.]*
echo "=== Extract backup files ==="
tar -xzf ./Full/tmp/backup/moodle.tar.gz -C /bitnami/
tar -xzf ./Full/tmp/backup/moodledata.tar.gz -C /bitnami/
echo "=== Move backup files ==="
mv /bitnami/mountData/moodle/* /bitnami/moodle/
mv /bitnami/mountData/moodle/.[!.]* /bitnami/moodle/
mv /bitnami/mountData/moodledata/* /bitnami/moodledata/
mv /bitnami/mountData/moodledata/.[!.]* /bitnami/moodledata/
# Set moodle user 1001
chown -R 1001 /bitnami/moodle
chown -R 1001 /bitnami/moodledata

cd /bitnami/
echo "=== Clear DB ==="
{{ if .Values.mariadb.enabled -}}
MYSQL_PWD="$DATABASE_PASSWORD" mariadb -h "$DATABASE_HOST" -u "$DATABASE_USER" -P "$DATABASE_PORT" -e "DROP DATABASE ${DATABASE_NAME};"
MYSQL_PWD="$DATABASE_PASSWORD" mariadb -h "$DATABASE_HOST" -u "$DATABASE_USER" -P "$DATABASE_PORT" -e "CREATE DATABASE ${DATABASE_NAME};"
{{- else -}}
# This command helps with - ERROR: database "moodle" is being accessed by other users
PGPASSWORD="$DATABASE_PASSWORD" psql -h "$DATABASE_HOST" -p "$DATABASE_PORT" -U "$DATABASE_USER" -c "REVOKE CONNECT ON DATABASE ${DATABASE_NAME} FROM public;SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pid <> pg_backend_pid() AND pg_stat_activity.datname = '${DATABASE_NAME}';"
PGPASSWORD="$DATABASE_PASSWORD" psql -h "$DATABASE_HOST" -p "$DATABASE_PORT" -U "$DATABASE_USER" -d postgres -c "DROP DATABASE ${DATABASE_NAME}"
PGPASSWORD="$DATABASE_PASSWORD" psql -h "$DATABASE_HOST" -p "$DATABASE_PORT" -U "$DATABASE_USER" -d postgres -c "CREATE DATABASE ${DATABASE_NAME}"
{{- end }}

echo "=== Copy dump to DB ==="
{{ if .Values.mariadb.enabled -}}
gunzip ./Full/tmp/backup/moodle_mariadb_dump_*
mv ./Full/tmp/backup/moodle_mariadb_dump_* moodledb_dump.sql
{{- else -}}
gunzip ./Full/tmp/backup/moodle_postgresqldb_dump_*
mv ./Full/tmp/backup/moodle_postgresqldb_dump_* moodledb_dump.sql
{{- end }}

{{ if .Values.mariadb.enabled -}}
MYSQL_PWD="$DATABASE_PASSWORD" mariadb -h "$DATABASE_HOST" -P "$DATABASE_PORT" -u "$DATABASE_USER" "$DATABASE_NAME" < moodledb_dump.sql
{{- else -}}
PGPASSWORD="$DATABASE_PASSWORD" psql -h "$DATABASE_HOST" -p "$DATABASE_PORT" -U "$DATABASE_USER" "$DATABASE_NAME"  < moodledb_dump.sql
{{- end }}
echo "=== Finished DB restore ==="

echo "=== Scaling deployment replicas to $replicas ==="
kubectl scale "deployment/${deployment_name}" --replicas=$replicas -n {{ .Release.Namespace }}
sleep 2
scaledTo=$(kubectl get "deployment/${deployment_name}" -n {{ .Release.Namespace }} -o=jsonpath='{.status.replicas}')
echo "=== Deployment scaled to: $scaledTo ==="