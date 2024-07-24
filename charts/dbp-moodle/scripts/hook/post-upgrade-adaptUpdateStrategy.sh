#!/bin/bash

cur_update_strategy="$(kubectl patch deploy/moodle -n infra-02 -p '{"spec": {"strategy": {"type": "Recreate"}}}')"

printf 'Current updateStrategy is "%s"' "$cur_update_strategy"

if [ "$cur_update_strategy" != "RollingUpdate" ]; then
    printf 'Reverting updateStrategy to RollingUpdate'
    kubectl patch deploy/moodle -n infra-02 -p '{"spec": {"strategy": {"type": "RollingUpdate"}}}'
fi