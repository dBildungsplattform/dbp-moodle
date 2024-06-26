#!/bin/bash
# create destination dir if not exists
set -e
if [ ! -d /backup ]
then
    mkdir -p /backup
fi

curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update

apt install duply
# Install postgresql-client-14
apt-get -y remove postgresql-client-common
apt-get -y install ca-certificates gnupg
apt-get install apt-transport-https --yes
apt-get -y install mariadb-client
apt-get -y install postgresql-client-14
pg_dump -V
pip install boto

#Cleanup after finish only if not an Update Backup (Normal Backup has no CliUpdate file)
#If Update Backup: depending on exit code create the signal for the Update Helper Job with success or failure
function clean_up() {
    exit_code=$?
    if ! [ -a /mountData/moodledata/CliUpdate ]
    then
        echo "=== Starting cleanup ==="
        echo "=== Stopping Maintenance Mode ==="
        rm -f /mountData/moodledata/climaintenance.html

        echo "=== Turn on liveness and readiness probe ==="
        helm upgrade --reuse-values --set livenessProbe.enabled=true --set readinessProbe.enabled=true moodle bitnami/moodle --namespace {{ .Release.Namespace }}

        echo "=== Unsuspending moodle cronjob ==="
        kubectl patch cronjobs moodle-{{ .Release.Namespace }}-cronjob-php-script -n {{ .Release.Namespace }} -p '{"spec" : {"suspend" : false }}'
    elif [ $exit_code -eq 0 ]
    then
    echo "=== Update Backup was successful with exit code $exit_code ==="
        rm -f /mountData/moodledata/UpdateBackupFailure
        touch /mountData/moodledata/UpdateBackupSuccess
        exit $exit_code
    else
        echo "=== Update Backup failed with exit code $exit_code ==="
        rm -f /mountData/moodledata/UpdateBackupSuccess
        touch /mountData/moodledata/UpdateBackupFailure
        exit $exit_code
    fi
}

trap "clean_up" EXIT

# install kubectl
curl -LO https://dl.k8s.io/release/v{{ .Values.global.kubectl_version }}/bin/linux/amd64/kubectl
chmod +x kubectl
mv ./kubectl /usr/local/bin/kubectl
apt-get -y install helm
helm repo add bitnami https://charts.bitnami.com/bitnami

#If the Backup is done for the Update it skips the preparation because the Update Helper already did this
if ! [ -a /mountData/moodledata/CliUpdate ]
then
    #Suspend the cronjob to avoid errors due to missing moodle
    echo "=== Suspending moodle cronjob ==="
    kubectl patch cronjobs moodle-{{ .Release.Namespace }}-cronjob-php-script -n {{ .Release.Namespace }} -p '{"spec" : {"suspend" : true }}'

    echo "=== Turn off liveness and readiness probe ==="
    helm upgrade --reuse-values --set livenessProbe.enabled=false --set readinessProbe.enabled=false moodle --wait bitnami/moodle --namespace {{ .Release.Namespace }}
    
    kubectl rollout status deployment/moodle

    #Wait for running Jobs to finish to avoid errors
    echo "=== Waiting for Jobs to finish ==="
    sleep 30
    
    echo "=== Starting Maintenance mode ==="
    echo '<h1>Sorry, maintenance in progress</h1>' > /mountData/moodledata/climaintenance.html
fi

echo "=== start backup ==="
date +%Y%m%d_%H%M%S%Z

cd /backup
# get dump of db
echo "=== start DB dump ==="
export DATE=$( date "+%Y-%m-%d" )

{% if moodle_use_mariadb %}
MYSQL_PWD="$MARIADB_PASSWORD" mysqldump -h moodle-mariadb -P 3306 -u moodle moodle > moodle_mariadb_dump_$DATE.sql
gzip moodle_mariadb_dump_$DATE.sql
{% else %}
PGPASSWORD="$POSTGRESQL_PASSWORD" pg_dump -h moodle-postgres-postgresql -p 5432 -U postgres moodle > moodle_postgresqldb_dump_$DATE.sql
gzip moodle_postgresqldb_dump_$DATE.sql
{% endif %}

# get moodle folder
echo "=== start moodle directory backup ==="
tar -zcf moodle.tar.gz /mountData/moodle/

# get moodledata folder
echo "=== start moodledata directory backup ==="
if [ -a /mountData/moodledata/CliUpdate ]
then
    #Backup during the Moodle Update Process
    tar --exclude="/mountData/moodledata/cache" --exclude="/mountData/moodledata/sessions" --exclude="/mountData/moodledata/moodle-backup" --exclude="/mountData/moodledata/CliUpdate" -zcf moodledata.tar.gz /mountData/moodledata/
else
    #Regular scheduled daily Backup process
    tar --exclude="/mountData/moodledata/cache" --exclude="/mountData/moodledata/sessions" -zcf moodledata.tar.gz /mountData/moodledata/
fi

echo "=== Start duply process ==="
cd /etc/duply/default
for cert in *.asc
    do
    echo "=== Import key $cert ==="
    gpg --import --batch $cert
    done
for fpr in $(gpg --batch --no-tty --command-fd 0 --list-keys --with-colons | awk -F: '/fpr:/ {print $10}' | sort -u); 
    do
    echo "=== Trusts key $fpr ==="
    echo -e "5\ny\n" | gpg --batch --no-tty --command-fd 0 --expert --edit-key $fpr trust;
    done
echo "=== Execute backup ==="
/usr/bin/duply default backup
/usr/bin/duply default status
cd /
rm -rf /backup
echo "=== backup finished ==="
echo "=== Clean up old backups ==="
/usr/bin/duply default purge --force
date +%Y%m%d_%H%M%S%Z