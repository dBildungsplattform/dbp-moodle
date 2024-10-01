#!/bin/bash
set -e

kubectl get pods -n {{ .Release.Namespace }} | egrep "^moodle-[a-z0-9]{8,10}-[a-z0-9]{5,5}"
kubectl exec $(kubectl get pods -n {{ .Release.Namespace }} --field-selector=status.phase=Running | egrep "^moodle-[a-z0-9]{5,10}-[a-z0-9]{3,5}[^a-z0-9]") -- /opt/bitnami/php/bin/php ./bitnami/moodle/admin/cli/cron.php
echo "Command '/opt/bitnami/php/bin/php ./bitnami/moodle/admin/cli/cron.php' has been run!"