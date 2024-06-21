#!/bin/bash
# create destination dir if not exists
set -e
if [ ! -d /backup ]
then
mkdir -p /backup
fi

curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
apt-get update

apt install duply
# Install mariadb-client and postgresql-client-14
# Needed for moodle restore
# Differs from other backup Helm Charts
apt-get -y remove postgresql-client-common
apt-get -y install ca-certificates gnupg
apt-get -y install mariadb-client
apt-get -y install postgresql-client-14
pg_dump -V

# install kubectl
curl -LO https://dl.k8s.io/release/v{{ .Values.global.kubectl_version }}/bin/linux/amd64/kubectl
chmod +x kubectl
mv ./kubectl /usr/local/bin/kubectl

# get current replicas and scale down deployment
replicas=$(kubectl get deployment -n {{ .Release.Namespace }} moodle -o=jsonpath='{.status.replicas}')
if [ $replicas -eq 0 ]
then 
replicas=1
fi
echo "=== Scale Moodle Deployment to 0 replicas for restore operation ==="
echo "=== Current replicas detected: $replicas ==="
kubectl scale deployment/moodle --replicas=0 -n {{ .Release.Namespace }}

# restore
cd /etc/duply/default
for cert in *.asc
do
echo "=== Import key $cert ==="
gpg --import --batch $cert
done
for fpr in $(gpg --batch --no-tty --command-fd 0 --list-keys --with-colons  | awk -F: '/fpr:/ {print $10}' | sort -u); 
do
echo "=== Trusts key $fpr ==="
echo -e "5\ny\n" |  gpg --batch --no-tty --command-fd 0 --expert --edit-key $fpr trust;
done

cd /bitnami/
echo "=== Download Backup ==="
duply default restore Full
echo "=== Clear PVC ==="
rm -rf /binami/moodle/*
rm -rf /binami/moodledata/*
echo "=== Extract Backup Files ==="
tar -xzf ./Full/backup/moodle.tar.gz -C /bitnami/
tar -xzf ./Full/backup/moodledata.tar.gz -C /bitnami/
# set Moodle user 1001
chown -R 1001 /bitnami/moodle
chown -R 1001 /bitnami/moodledata

cd /bitnami/
echo "=== Clear DB ==="

{{- if moodle_use_mariadb }}
MYSQL_PWD="$MARIADB_PASSWORD" mariadb -u moodle -h moodle-mariadb --port=3306 -e "DROP DATABASE moodle;"
MYSQL_PWD="$MARIADB_PASSWORD" mariadb -u moodle -h moodle-mariadb --port=3306 -e "CREATE DATABASE moodle;"
{{- else }}
# if you cant delete the DB use this command (ERROR: database "moodle" is being accessed by other users)
# PGPASSWORD="$POSTGRESQL_PASSWORD" psql -U postgres -h moodle-postgres-postgresql -c "REVOKE CONNECT ON DATABASE moodle FROM public;SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'moodle';"
PGPASSWORD="$POSTGRESQL_PASSWORD" psql -U postgres -h moodle-postgres-postgresql -c "DROP DATABASE moodle"
PGPASSWORD="$POSTGRESQL_PASSWORD" psql -U postgres -h moodle-postgres-postgresql -c "CREATE DATABASE moodle"
{{- endif }}

echo "=== Copy dump to DB ==="
{{- if moodle_use_mariadb }}
gunzip ./Full/backup/moodle_mariadb_dump_*
mv ./Full/backup/moodle_mariadb_dump_* moodledb_dump.sql
{{- else }}
gunzip ./Full/backup/moodle_postgresqldb_dump_*
mv ./Full/backup/moodle_postgresqldb_dump_* moodledb_dump.sql
{{- endif }}

{{- if moodle_use_mariadb }}
MYSQL_PWD="$MARIADB_PASSWORD" mariadb -u moodle -h moodle-mariadb moodle < moodledb_dump.sql
{{- else }}
PGPASSWORD="$POSTGRESQL_PASSWORD" psql -U postgres -h moodle-postgres-postgresql moodle < moodledb_dump.sql
{{- endif }}
echo "=== Finish Restore ==="

echo "=== Scaling deployment replicas to $replicas ==="
kubectl scale deployment/moodle --replicas=$replicas -n {{ .Release.Namespace }}
sleep 2
scaledTo=$(kubectl get deployment -n {{ .Release.Namespace }} moodle -o=jsonpath='{.status.replicas}')
echo "=== Deployment scaled to: $scaledTo ==="