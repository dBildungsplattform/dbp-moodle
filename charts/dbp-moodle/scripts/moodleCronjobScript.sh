#!/bin/bash
set -e

moodle_pod=$(kubectl -n {{ .Release.Namespace }} get pods -l app.kubernetes.io/name=moodle -o jsonpath='{.items[0].metadata.name}')

echo "Waiting for pod [${moodle_pod}] to be ready..."
kubectl -n "{{ .Release.Namespace }}" wait --for=condition=Ready pod/"${moodle_pod}" --timeout={{ .Values.dbpMoodle.moodlecronjob.wait_timeout }}
echo "Executing command in pod: ${moodle_pod}"
kubectl exec -n {{ .Release.Namespace }} "${moodle_pod}" -- /opt/bitnami/php/bin/php ./bitnami/moodle/admin/cli/cron.php
echo "Command '/opt/bitnami/php/bin/php ./bitnami/moodle/admin/cli/cron.php' has been run on pod [${moodle_pod}]!"
