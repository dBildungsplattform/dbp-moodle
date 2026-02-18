#!/bin/bash

major_minor="${MOODLE_VERSION%.*}"

plugin_dependency_list=(
    local_wunderbyte_table # Dependency of mod_booking
    tool_certificate # Dependency of mod_coursecertificate
    qbehaviour_adaptivemultipart # Dependency of qtype_stack
    qbehaviour_dfexplicitvaildate # Dependency of qtype_stack
    qbehaviour_dfcbmexplicitvaildate # Dependency of qtype_stack
)

plugin_list=(
    mod_booking
    theme_boost_magnific
    theme_boost_union
    mod_choicegroup
    mod_coursecertificate
    mod_etherpadlite
    mod_hvp
    mod_pdfannotator
    format_remuiformat
    local_staticpage
    format_tiles
    format_topcoll
    mod_unilabel
    block_xp
    mod_zoom
    filter_filtercodes
    filter_shortcodes
    tool_heartbeat
    availability_cohort
    mod_board
    mod_checklist
    block_sharing_cart
    qtype_stack
    block_stash
    block_completion_progress
    tool_coursearchiver
)

cd /plugins || exit 1

check_plugin_size() {
    plugin_name=$1    
    plugin_size=$(stat -c%s "/plugins/${plugin_name}.zip")
    if [ "$plugin_size" -eq 0 ]; then
        echo "ERROR: Moodle Plugin '$plugin_name' is empty (size 0 bytes). Possible Download error." >&2
        exit 1
    fi
}

download_oidc() {
    target_branch="v_45" # eLeDia currently doesn't use any tags, we always use the latest version on branch v_45

    git clone https://github.com/dBildungsplattform/dbp-moodle-plugin-oidc.git
    cd dbp-moodle-plugin-oidc/ || exit 1
    git checkout ${target_branch}
    # create the zip archive in the initial directory, s.t. it can be treated equally to the other plugins
    (cd auth && zip -r ../../auth_oidc.zip oidc)
    cd ..
    rm -rf dbp-moodle-plugin-oidc/
}

download_oidc
moosh plugin-list > /dev/null

for plugin in "${plugin_dependency_list[@]}"; do
    index="${plugin_dependency_list[$plugin]}"
    
    # if (( $index > 0 && $index % 40 == 0 )); then
    #     echo "Reached batch of 40 plugins. Sleeping for 30 seconds..."
    #     sleep 1
    # fi
    moosh plugin-download -v "$major_minor" "$plugin"
    check_plugin_size "$plugin"
done

for plugin in "${plugin__list[@]}"; do
    moosh plugin-download -v "$major_minor" "$plugin"
    check_plugin_size "$plugin"
done

moosh plugin-download -v 3.7 customfield_dynamic
check_plugin_size "customfield_dynamic"

# Plugins
moosh plugin-download -v "$major_minor" mod_skype
moosh plugin-download -v "$major_minor" format_flexsections
moosh plugin-download -v "$major_minor" format_multitopic
moosh plugin-download -v "$major_minor" theme_adaptable
moosh plugin-download -v "$major_minor" tool_usersuspension
moosh plugin-download -v "$major_minor" tool_dynamic_cohorts
