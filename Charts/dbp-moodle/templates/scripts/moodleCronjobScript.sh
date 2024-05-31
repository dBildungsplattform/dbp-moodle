 #!/bin/bash
set -e
# install kubectl
{{ .Values.global.get_kubectl_command }}
kubectl get pods -n {{ .Values.global.namespace }} | egrep "^moodle-[a-z0-9]{8,10}-[a-z0-9]{5,5}"
kubectl exec $(kubectl get pods -n {{ .Values.global.namespace }} --field-selector=status.phase=Running | egrep "^moodle-[a-z0-9]{5,10}-[a-z0-9]{3,5}[^a-z0-9]") -- /opt/bitnami/php/bin/php ./bitnami/moodle/admin/cli/cron.php
echo "Command '/opt/bitnami/php/bin/php ./bitnami/moodle/admin/cli/cron.php' has been run!"