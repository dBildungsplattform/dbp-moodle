#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

health_file="/tmp/healthy"

get_current_deployment_image() {
    kubectl get "deploy/{{ .Release.Name }}" -n "{{ .Release.Namespace }}" -o jsonpath='{..image}' |\
        tr -s '[:space:]' '\n' |\
        grep '{{- .Values.moodle.image.repository -}}'
}

touch "${health_file}"

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
kubectl patch cronjobs "{{ .Release.Name }}"-moodlecronjob-"{{ include "moodlecronjob.job_name" . }}" -n "{{ .Release.Namespace }}" -p '{"spec" : {"suspend" : true }}'

printf 'Scaling deployment "{{ .Release.Name }}" to 0 replicas\n'
kubectl patch "deploy/{{ .Release.Name }}" -n "{{ .Release.Namespace }}" -p '{"spec":{"replicas": 0}}'

{{ if .Values.dbpMoodle.backup.enabled }}
if [ "$BACKUP_ENABLED" = true ]; then
    printf 'Starting pre-update backup\n'
    kubectl create job moodle-pre-update-backup-job -n "{{ .Release.Namespace }}" --from=cronjob.batch/moodle-backup-cronjob-backup
    printf 'Waiting for backup to finish...\n'
    kubectl wait --for=condition=complete --timeout=10m job/moodle-pre-update-backup-job
fi
{{ end }}
