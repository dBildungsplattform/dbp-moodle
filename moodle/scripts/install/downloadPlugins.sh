#!/bin/bash

major_minor="${MOODLE_VERSION%.*}"

cd /plugins || exit 1

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

# Dependencies
moosh plugin-download -v "$major_minor" local_wunderbyte_table # Dependency of mod_booking
moosh plugin-download -v "$major_minor" tool_certificate # Dependency of mod_coursecertificate
moosh plugin-download -v "$major_minor" qbehaviour_adaptivemultipart # Dependency of qtype_stack
moosh plugin-download -v "$major_minor" qbehaviour_dfexplicitvaildate # Dependency of qtype_stack
moosh plugin-download -v "$major_minor" qbehaviour_dfcbmexplicitvaildate # Dependency of qtype_stack

# Plugins
moosh plugin-download -v "$major_minor" mod_etherpadlite
moosh plugin-download -v "$major_minor" mod_hvp
moosh plugin-download -v "$major_minor" mod_pdfannotator
moosh plugin-download -v "$major_minor" mod_skype
moosh plugin-download -v "$major_minor" mod_zoom
moosh plugin-download -v "$major_minor" mod_booking
moosh plugin-download -v "$major_minor" mod_unilabel
moosh plugin-download -v "$major_minor" mod_choicegroup
moosh plugin-download -v "$major_minor" mod_board
moosh plugin-download -v "$major_minor" local_staticpage
moosh plugin-download -v "$major_minor" format_remuiformat
moosh plugin-download -v "$major_minor" format_tiles
moosh plugin-download -v "$major_minor" format_topcoll
moosh plugin-download -v "$major_minor" format_flexsections
moosh plugin-download -v "$major_minor" format_multitopic
moosh plugin-download -v "$major_minor" block_xp
moosh plugin-download -v "$major_minor" mod_coursecertificate
moosh plugin-download -v "$major_minor" theme_adaptable
moosh plugin-download -v "$major_minor" theme_boost_union
moosh plugin-download -v "$major_minor" theme_boost_magnific
moosh plugin-download -v "$major_minor" tool_usersuspension
moosh plugin-download -v "$major_minor" tool_dynamic_cohorts
moosh plugin-download -v 3.7 customfield_dynamic
sleep 60 # prevent Error 429 Too Many Requests 
moosh plugin-download -v "$major_minor" filter_shortcodes
moosh plugin-download -v "$major_minor" filter_filtercodes
moosh plugin-download -v "$major_minor" availability_cohort
moosh plugin-download -v "$major_minor" tool_heartbeat
moosh plugin-download -v "$major_minor" qtype_stack
moosh plugin-download -v "$major_minor" format_remuiformat
moosh plugin-download -v "$major_minor" mod_checklist
moosh plugin-download -v "$major_minor" block_stash
moosh plugin-download -v "$major_minor" block_completion_progress
moosh plugin-download -v "$major_minor" tool_coursearchiver
moosh plugin-download -v "$major_minor" block_sharing_cart
moosh plugin-download -v "$major_minor" mod_subcourse
moosh plugin-download -v "$major_minor" mod_videotime