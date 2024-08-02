#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

get_current_deployment_image() {
    kubectl get "deploy/{{ .Release.Name }}" -n "{{ .Release.Namespace }}" -o jsonpath='{..image}' |\
        tr -s '[:space:]' '\n' |\
        grep '{{- .Values.moodle.image.repository -}}'
}

new_image="{{- .Values.moodle.image.registry -}}/{{- .Values.moodle.image.repository -}}:{{- .Values.moodle.image.tag -}}"
cur_image="$(get_current_deployment_image)"

printf 'Comparing old image "%s" against new image "%s"\n' "$cur_image" "$new_image"

if [ "$new_image" = "$cur_image" ]; then
    printf 'No update taking place. No scale down needed\n'
else
    printf 'Image change detected, Scaling deployment "{{ .Release.Name }}" to 0 replicas\n'
    kubectl patch "deploy/{{ .Release.Name }}" -n "{{ .Release.Namespace }}" -p '{"spec":{"replicas": 0}}'
fi