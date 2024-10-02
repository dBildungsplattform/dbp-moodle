#!/bin/bash
set -e

moodle_pods=$(kubectl -n {{ .Release.Namespace }} get pods -l app.kubernetes.io/name=moodle -o jsonpath='{.items[*].metadata.name}')

for pod in "${moodle_pods[@]}"; do
  echo "Waiting for pod [${pod}] to be ready..."
  kubectl -n {{ .Release.Namespace }} wait --for=condition=Ready pod/${pod} --timeout=15m
  echo "Executing command in pod: ${pod}"
  kubectl exec --kubeconfig -n {{ .Release.Namespace }} "${pod}" -- /opt/bitnami/php/bin/php ./bitnami/moodle/admin/cli/cron.php
  echo "Command '/opt/bitnami/php/bin/php ./bitnami/moodle/admin/cli/cron.php' has been run on [${pod}]!"
done
