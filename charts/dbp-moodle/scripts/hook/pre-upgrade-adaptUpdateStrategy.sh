#!/bin/bash

get_current_deployment_image() {
    kubectl get deploy/moodle -n infra-02 -o jsonpath='{..image}' |\
        tr -s '[:space:]' '\n' |\
        grep 'ghcr.io/dbildungsplattform/moodle'
}

new_image="{{- .Values.moodle.image.repository -}}:{{- .Values.moodle.image.tag -}}"
cur_image="$(get_current_deployment_image)"

printf 'Comparing "%s" against "%s"' "$new_image" "$cur_image"

if [ "$new_image" != "$cur_image" ]; then
    printf 'Image change detected, changing updateStrategy to "Recreate"'
    kubectl patch deploy/moodle -n infra-02 -p '{"spec": {"strategy": {"type": "Recreate"}}}'
fi