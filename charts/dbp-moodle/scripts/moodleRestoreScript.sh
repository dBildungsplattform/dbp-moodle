#!/bin/bash
# Create destination dir if not exists
set -e
if [ ! -d /backup ]; then
    mkdir -p /backup
fi

curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
apt-get update

apt install duply
# Install mariadb-client or postgresql-client-14
# Needed for moodle restore
# Differs from other backup Helm Charts
apt-get -y install ca-certificates gnupg
{{ if .Values.mariadb.enabled }}
apt-get -y install mariadb-client
{{ else }}
apt-get -y remove postgresql-client-common
apt-get -y install postgresql-client-14
{{ end }}
pg_dump -V

# Install kubectl
curl -LO https://dl.k8s.io/release/v{{ .Values.global.kubectl_version }}/bin/linux/amd64/kubectl
chmod +x kubectl
mv ./kubectl /usr/local/bin/kubectl

# Get current replicas and scale down deployment
replicas=$(kubectl get deployment/{{ .Release.Name }} -n {{ .Release.Namespace }} -o=jsonpath='{.status.replicas}')
echo "=== Current replicas detected: $replicas ==="
if [ -z "$replicas" ] || [ "$replicas" -eq 0 ]; then 
    replicas=1
fi
echo "=== Scale moodle deployment to 0 replicas for restore operation ==="
kubectl scale deployment/{{ .Release.Name }} --replicas=0 -n {{ .Release.Namespace }}
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
rm -rf /bitnami/moodle/.??*
rm -rf /bitnami/moodledata/*
rm -rf /bitnami/moodledata/.??*
echo "=== Extract backup files ==="
tar -xzf ./Full/backup/moodle.tar.gz -C /bitnami/
tar -xzf ./Full/backup/moodledata.tar.gz -C /bitnami/
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

{{ if .Values.mariadb.enabled }}
MYSQL_PWD="$MARIADB_PASSWORD" mariadb -u {{ .Values.mariadb.auth.username }} -h {{ .Release.Name }}-mariadb --port={{ .Values.mariadb.primary.containerPorts.mysql }} -e "DROP DATABASE {{ .Values.mariadb.auth.database }};"
MYSQL_PWD="$MARIADB_PASSWORD" mariadb -u {{ .Values.mariadb.auth.username }} -h {{ .Release.Name }}-mariadb --port={{ .Values.mariadb.primary.containerPorts.mysql }} -e "CREATE DATABASE {{ .Values.mariadb.auth.database }};"
{{ else }}
# This command helps with - ERROR: database "moodle" is being accessed by other users
PGPASSWORD="$POSTGRESQL_PASSWORD" psql -U {{ .Values.postgresql.auth.username }} -h {{ .Release.Name }}-postgres-postgresql -c "REVOKE CONNECT ON DATABASE {{ .Values.postgresql.auth.database }} FROM public;SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '{{ .Values.postgresql.auth.database }}';"
PGPASSWORD="$POSTGRESQL_PASSWORD" psql -U {{ .Values.postgresql.auth.username }} -h {{ .Release.Name }}-postgres-postgresql -c "DROP DATABASE {{ .Values.postgresql.auth.database }}"
PGPASSWORD="$POSTGRESQL_PASSWORD" psql -U {{ .Values.postgresql.auth.username }} -h {{ .Release.Name }}-postgres-postgresql -c "CREATE DATABASE {{ .Values.postgresql.auth.database }}"
{{ end }}

echo "=== Copy dump to DB ==="
{{ if .Values.mariadb.enabled }}
gunzip ./Full/backup/moodle_mariadb_dump_*
mv ./Full/backup/moodle_mariadb_dump_* moodledb_dump.sql
{{ else }}
gunzip ./Full/backup/moodle_postgresqldb_dump_*
mv ./Full/backup/moodle_postgresqldb_dump_* moodledb_dump.sql
{{ end }}

{{ if .Values.mariadb.enabled }}
MYSQL_PWD="$MARIADB_PASSWORD" mariadb -u {{ .Values.mariadb.auth.username }} -h {{ .Release.Name }}-mariadb {{ .Values.mariadb.auth.database }} < moodledb_dump.sql
{{ else }}
PGPASSWORD="$POSTGRESQL_PASSWORD" psql -U {{ .Values.postgresql.auth.username }} -h {{ .Release.Name }}-postgres-postgresql {{ .Values.postgresql.auth.database }} < moodledb_dump.sql
{{ end }}
echo "=== Finish restore ==="

echo "=== Scaling deployment replicas to $replicas ==="
kubectl scale deployment/{{ .Release.Name }} --replicas=$replicas -n {{ .Release.Namespace }}
sleep 2
scaledTo=$(kubectl get deployment/{{ .Release.Name }} -n {{ .Release.Namespace }} -o=jsonpath='{.status.replicas}')
echo "=== Deployment scaled to: $scaledTo ==="