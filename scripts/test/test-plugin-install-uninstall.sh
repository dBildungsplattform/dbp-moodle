#!/bin/bash

# checks:
# - check if all disabled works and nothing happens
# - install plugin & rerun to ensure nothing changes
# - install multiple plugins (& rerun)
# - uninstall plugin (& rerun)
# - uninstall multiple plugins (& rerun)
# - install plugin & uninstall at the same time (& rerun)
# - install plugin & uninstall multiple at the same time (& rerun)

set -o errexit
# set -o nounset
set -o pipefail

plugin_base_list=$(cat <<EOF
kaltura:kaltura:
wunderbyte_table:local_wunderbyte_table:local/wunderbyte_table
certificate:tool_certificate:admin/tool/certificate
etherpadlite:mod_etherpadlite:mod/etherpadlite
hvp:mod_hvp:mod/hvp
groupselect:mod_groupselect:mod/groupselect
jitsi:mod_jitsi:mod/jitsi
pdfannotator:mod_pdfannotator:mod/pdfannotator
skype:mod_skype:mod/skype
zoom:mod_zoom:mod/zoom
booking:mod_booking:mod/booking
reengagement:mod_reengagement:mod/reengagement
unilabel:mod_unilabel:mod/unilabel
geogebra:mod_geogebra:mod/geogebra
remuiformat:format_remuiformat:course/format/remuiformat
tiles:format_tiles:course/format/tiles
topcoll:format_topcoll:course/format/topcoll
oidc:auth_oidc:auth/oidc
saml2:auth_saml2:auth/saml2
dash:block_dash:blocks/dash
sharing_cart:block_sharing_cart:blocks/sharing_cart
xp:block_xp:blocks/xp
coursecertificate:mod_coursecertificate:mod/coursecertificate
boost_union:theme_boost_union:theme/boost_union
EOF
)

get_plugin_string() {
    local args=("$@")
    local plugin_list
    plugin_list=""
    i=0
    
    default="false"
    if [[ "$1" == "-i" ]]; then
        default="true"
        shift
        args=("$@")
    fi

    for plugin in $plugin_base_list; do
        enabled="$default"

        for arg in "${args[@]}"; do
            if [ "$i" -eq "$arg" ]; then
                enabled="true"
                break
            fi
        done

        plugin_list="${plugin_list}${plugin}:${enabled}\\n"
        ((i++))
    done
    echo -e "$plugin_list"
}

declare -g step_count=0
# Function to print step and increment step counter
print_step() {
    printf "##########################################\n"
    printf "Step %d: %s\n" $step_count "$1"
    printf "##########################################\n"
    set +o errexit # for some reason the incrementing errors some times??
    (( step_count++ ))
    set -o errexit    
}

do_step() {
    local plugin_string

    plugin_string="$( get_plugin_string "$@" )"

    # there is always a rerun to ensure idempotence is working
    MOODLE_PLUGINS="$plugin_string" ENABLE_KALTURA=false /scripts/applyPluginState.sh
    printf "################# re-run #################\n"
    MOODLE_PLUGINS="$plugin_string" ENABLE_KALTURA=false /scripts/applyPluginState.sh
}

print_step "Testing do nothing if none enabled"
do_step -1

print_step "Install etherpadlite"
do_step 3

print_step "Uninstall etherpadlite"
do_step -1 

print_step "Install etherpadlite, hvp"
do_step 3 4

print_step "Uninstall all (etherpadlite, hvp)"
do_step -1 

print_step "preparation: install groupselect"
do_step 5

print_step "preparation: uninstall groupselect & install jitsi"
do_step 6

print_step "Cleanup: uninstall jitsi"
do_step -1

print_step "Install all"
do_step -i -1

print_step "Uninstall all"
do_step -1

printf "All checks finished successfully"