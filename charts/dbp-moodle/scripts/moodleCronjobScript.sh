#!/bin/bash
set -e
# get kubectl command
curl -LO https://dl.k8s.io/release/v{{ .Values.global.kubectl_version }}/bin/linux/amd64/kubectl
chmod +x kubectl
mv ./kubectl /usr/local/bin/kubectl

kubectl get pods -n {{ .Release.Namespace }} | egrep "^moodle-[a-z0-9]{8,10}-[a-z0-9]{5,5}"
kubectl exec $(kubectl get pods -n {{ .Release.Namespace }} --field-selector=status.phase=Running | egrep "^moodle-[a-z0-9]{5,10}-[a-z0-9]{3,5}[^a-z0-9]") -- /opt/bitnami/php/bin/php ./bitnami/moodle/admin/cli/cron.php
echo "Command '/opt/bitnami/php/bin/php ./bitnami/moodle/admin/cli/cron.php' has been run!"