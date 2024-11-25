#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

health_file="/tmp/healthy"

# Deployment has "-moodle" appended if the Release.Name does not contain "moodle" 
deployment_name="{{ .Release.Name }}"
if [[ "$deployment_name" != "moodle" && "$deployment_name" != *"moodle"* ]]; then
    deployment_name="${deployment_name}-moodle"
fi

get_current_deployment_image() {
    kubectl get "deploy/${deployment_name}" -n "{{ .Release.Namespace }}" -o jsonpath='{..image}' |\
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

printf 'Scaling deployment "%s" to 0 replicas\n' "$deployment_name"
kubectl patch "deploy/${deployment_name}" -n "{{ .Release.Namespace }}" -p '{"spec":{"replicas": 0}}'

{{ if .Values.dbpMoodle.backup.enabled }}
if [ "$BACKUP_ENABLED" = true ]; then
    printf 'Starting pre-update backup\n'
    kubectl create job moodle-pre-update-backup-job -n "{{ .Release.Namespace }}" --from="cronjob.batch/{{ include "backup-cronjob.job_name" . }}"
    printf 'Waiting for backup to finish...\n'
    kubectl wait --for=condition=complete --timeout=10m job/moodle-pre-update-backup-job
fi
{{ end }}

printf 'Preparations completed successfully, exting...'