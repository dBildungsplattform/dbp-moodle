#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

get_current_deployment_image() {
    kubectl get "deploy/{{ .Release.Name }}" -n "{{ .Release.Namespace }}" -o jsonpath='{..image}' |\
        tr -s '[:space:]' '\n' |\
        grep '{{- .Values.moodle.image.repository -}}'
}


asd() {
    kubectl create job moodle-update-backup-job --from=cronjob.batch/moodle-backup-cronjob-backup -n {{ .Release.Namespace }}
    kubectl patch cronjobs moodle-{{ .Release.Namespace }}-cronjob-php-script -n {{ .Release.Namespace }} -p '{"spec" : {"suspend" : true }}'
    kubectl patch deployment <deployment-name> --type=json -p='[{"op": "remove", "path": "/spec/template/spec/containers/0/livenessProbe"}]'

    # helm upgrade --reuse-values --set livenessProbe.enabled=false --set readinessProbe.enabled=false moodle --wait bitnami/moodle --namespace {{ .Release.Namespace }}
}

printf "Checking if update preparations are needed\n"

new_image="{{- .Values.moodle.image.registry -}}/{{- .Values.moodle.image.repository -}}:{{- .Values.moodle.image.tag -}}"
cur_image="$(get_current_deployment_image)"

printf 'Comparing old image "%s" against new image "%s"\n' "$cur_image" "$new_image"

if [ "$new_image" = "$cur_image" ]; then
    printf 'No update taking place, no preparations needed\n'
    exit
fi
printf 'Image change detected\n'

printf 'Disabling regular cronjob to prevent failing runs\n'
kubectl patch cronjobs moodle-"{{ .Release.Namespace }}"-cronjob-php-script -n "{{ .Release.Namespace }}" -p '{"spec" : {"suspend" : true }}'

# printf 'Disabling liveness probe to prevent alerts during update\n'
# kubectl patch deployment "deploy/{{ .Release.Name }}" --type=json -p='[{"op": "remove", "path": "/spec/template/spec/containers/0/livenessProbe"}]'

printf 'Scaling deployment "{{ .Release.Name }}" to 0 replicas\n'
kubectl patch "deploy/{{ .Release.Name }}" -n "{{ .Release.Namespace }}" -p '{"spec":{"replicas": 0}}'

if [ "$BACKUP_ENABLED" == "true" ]; then
    kubectl create job moodle-pre-update-backup-job -n "{{ .Release.Namespace }}" --from=cronjob.batch/moodle-backup-cronjob-backup
fi