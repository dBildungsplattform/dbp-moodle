#!/bin/bash
if [ -a /volumes/moodledata/UpdateFailed ]
then
    echo "=== UpdateFailed file found, skipping Helper Job ==="
    exit 1
fi

curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update

apt-get install apt-transport-https --yes
#get kubectl command
curl -LO https://dl.k8s.io/release/v{{ .Values.global.kubectl_version }}/bin/linux/amd64/kubectl
chmod +x kubectl
mv ./kubectl /usr/local/bin/kubectl

apt-get -y install helm
helm repo add bitnami https://charts.bitnami.com/bitnami

unsuspend(){
    echo "=== Unsuspending moodle cronjob ==="
    kubectl patch cronjobs moodle-{{ .Release.Namespace }}-cronjob-php-script -n {{ .Release.Namespace }} -p '{"spec" : {"suspend" : false }}'
}

trap "unsuspend" EXIT

# get current available replicas (availableReplicas because we don't want the new Moodle pod from the RollingUpdate)
replicas=$(kubectl get deployment -n {{ .Release.Namespace }} moodle -o=jsonpath='{.status.availableReplicas}')
if [[ $replicas -eq 0 ]]; then 
    replicas=1
fi
echo "=== Current replicas detected: $replicas ==="

getMoodleVersion(){
    if [ -f /volumes/moodle/version.php ]; then
        LINE=$(grep release /volumes/moodle/version.php)
        REGEX="release\s*=\s*'([0-9]+\.[0-9]+\.[0-9]+)"
        if [[ $LINE =~ $REGEX ]]; then
            echo "=== The newly installed Moodle version is: ${BASH_REMATCH[1]} ==="
        fi
    else
        echo "=== No Moodle Version found ==="
        exit 1
    fi
}

scaleUpOnBackupFailure(){
    touch /volumes/moodledata/UpdateFailed
    rm -f /volumes/moodledata/climaintenance.html
    kubectl scale deployment/moodle --replicas=$replicas -n {{ .Release.Namespace }}
    exit 1
}

scaleUpOnInstallationFailure(){
    touch /volumes/moodledata/UpdateFailed
    rm -f /volumes/moodledata/climaintenance.html
    helm upgrade --reuse-values --set livenessProbe.enabled=true --set readinessProbe.enabled=true moodle bitnami/moodle --namespace {{ .Release.Namespace }}
    sleep 10
    kubectl scale deployment/moodle --replicas=$replicas -n {{ .Release.Namespace }}
    exit 1
}

handleFreshInstall(){
    if [ -z "{{ .Values.dbpMoodle.plugins.plugin_list }}" ]; then
        echo "=== Helm value pluginList is empty, stopping update helper job ==="
        rm /volumes/moodledata/FreshInstall
    else
        echo "=== Helm value pluginList is not empty, waiting for moodle to install ==="
        rm /volumes/moodledata/FreshInstall
        touch /volumes/moodledata/UpdatePlugins
        # readyness check of the Moodle installation
        sleep 400
        kubectl scale deployment/moodle -n {{ .Release.Namespace }} --replicas=0
        sleep 20
        kubectl scale deployment/moodle -n {{ .Release.Namespace }} --replicas=1
    fi
}

#Suspend the cronjob to avoid errors due to missing moodle
echo "=== Suspending moodle cronjob ==="
kubectl patch cronjobs moodle-{{ .Release.Namespace }}-cronjob-php-script -n {{ .Release.Namespace }} -p '{"spec" : {"suspend" : true }}'

echo "=== Starting waiting period for CliUpdate from Moodle Pod ==="
for i in {0..1001..2}
do
    if [ -a /volumes/moodledata/CliUpdate ]
    then
    echo "=== CliUpdate file found, starting Update process ==="
    break
    elif [ -a /volumes/moodledata/FreshInstall ]
    then
    echo "=== FreshInstall file found, starting first Plugin installation ==="
    handleFreshInstall
    exit 0
    elif [ $i -gt 998 ]
    then
    echo "=== Waited for set duration but no Update is required ==="
    sleep 2
    exit 0
    fi
    sleep 2
done

echo "=== Scale Moodle Deployment to 0 replicas for update operation ==="
kubectl scale deployment/moodle --replicas=0 -n {{ .Release.Namespace }}
sleep 10

#Backup job gets started here if stage == prod, otherwise skip full backup
if [ {{ .Values.global.stage }} == "prod" ]
then
    #Delete moodle-update-backup-job in case it already exists
    kubectl delete job moodle-update-backup-job -n {{ .Release.Namespace }}
    sleep 1
    kubectl create job moodle-update-backup-job --from=cronjob.batch/moodle-backup-cronjob-backup -n {{ .Release.Namespace }}

    #Wait for the Backup job to finish
    echo "=== Starting waiting period for full Backup  ==="
    for j in {0..900..2}
    do
    if [ -a /volumes/moodledata/UpdateBackupSuccess ]
    then
        echo "=== Update Backup successful, starting update installation process ==="
        rm -f /volumes/moodledata/UpdateBackupSuccess
        break
    elif [ -a /volumes/moodledata/UpdateBackupFailure ]
    then
        echo "=== The Update Backup Job failed and the old moodle Version will be started again ==="
        rm -f /volumes/moodledata/UpdateBackupFailure
        scaleUpOnBackupFailure
    elif [[ j -gt 896 ]]
    then
        echo "=== Full Backup timeout, fallback to old version ==="
        scaleUpOnBackupFailure
    fi
    sleep 2
    done
else
    echo "=== Skipping full Backup because of {{ .Values.global.stage }} ==="
fi

echo "=== Turn off liveness probe ==="
helm upgrade --reuse-values --set livenessProbe.enabled=false --set readinessProbe.enabled=false moodle --wait bitnami/moodle --namespace {{ .Release.Namespace }}
sleep 10
echo "=== Scale back to 1 replica to continue the Update ==="
kubectl scale deployment/moodle --replicas=1 -n {{ .Release.Namespace }}

echo "=== Waiting for Pod to install the Update ==="
for j in {0..1200..2}
do
    #The update has failed which gets visible by creation of the UpdateFailed File
    if [ -a /volumes/moodledata/UpdateFailed ]
    then
    echo "=== Update failed, manual intervention required ==="
    scaleUpOnInstallationFailure
    elif ! [ -a /volumes/moodledata/CliUpdate ] && ! [ -a /volumes/moodledata/UpdateFailed ]
    then
    echo "=== Update finished successfully, waiting for Moodle Database Update ==="
    sleep 300
    echo "=== Restore functionality ==="
    echo "=== Turn liveness & readiness probe back on again ==="
    helm upgrade --reuse-values --set livenessProbe.enabled=true --set readinessProbe.enabled=true moodle bitnami/moodle --namespace {{ .Release.Namespace }}
    sleep 10
    echo "=== Scale replicas to previous amount ==="
    kubectl scale deployment/moodle --replicas=$replicas -n {{ .Release.Namespace }}
    getMoodleVersion
    sleep 1
    exit 0
    fi
    sleep 2
done
echo "=== Update installation took to long, error ==="
scaleUpOnInstallationFailure