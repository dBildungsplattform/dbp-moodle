#!/bin/bash

major_minor="${MOODLE_VERSION%.*}"

download_kaltura() {
     local target_version="$1"
     latest_tag="$(curl -s https://api.github.com/repos/kaltura/moodle_plugin/releases | jq -r '.[].tag_name' | grep "$target_version" | head -1)"
     echo "latest_tag: ${latest_tag}"
     latest_zip_url="$(curl -s https://api.github.com/repos/kaltura/moodle_plugin/releases | jq -r ".[] | select(.tag_name == \"${latest_tag}\") | .assets[].browser_download_url")"
     echo "latest_zip_url: ${latest_zip_url}"
     curl -L -o kaltura.zip "$latest_zip_url"
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

cd /plugins || exit 1

download_kaltura "$major_minor"
download_oidc
moosh plugin-list > /dev/null

# Dependencies
moosh plugin-download -v "$major_minor" local_wunderbyte_table # Dependency of mod_booking
moosh plugin-download -v "$major_minor" tool_certificate # Dependency of mod_coursecertificate

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
moosh plugin-download -v "$major_minor" filter_shortcodes
moosh plugin-download -v "$major_minor" filter_filtercodes
moosh plugin-download -v "$major_minor" availability_cohort
moosh plugin-download -v "$major_minor" tool_heartbeat
sleep 60 # prevent Error 429 Too Many Requests 
moosh plugin-download -v "$major_minor" qbehaviour_adaptivemultipart # dependency of qtype_stack
moosh plugin-download -v "$major_minor" qbehaviour_dfexplicitvaildate # dependency of qtype_stack
moosh plugin-download -v "$major_minor" qbehaviour_dfcbmexplicitvaildate # dependency of qtype_stack
moosh plugin-download -v "$major_minor" qtype_stack
moosh plugin-download -v "$major_minor" format_remuiformat
moosh plugin-download -v "$major_minor" mod_checklist
moosh plugin-download -v "$major_minor" block_stash
moosh plugin-download -v "$major_minor" block_completion_progress
moosh plugin-download -v "$major_minor" tool_coursearchiver
moosh plugin-download -v "$major_minor" block_sharing_cart

# format_remuiformat /course/format/remuiformat
# mod_checklist -> /mod/checklist
# block_sharing_cart -> /blocks/sharing_cart
# qtype_stack -> /question/type/stack/ ## ERROR: Fehler: core\plugin_manager::remove_plugin_folder(): Argument #1 ($plugin) must be of type core\plugininfo\base, null given, called in [dirroot]/lib/classes/plugin_manager.php on line 1429
# block_stash -> /blocks/stash
# block_completion_progress -> /blocks/completion_progress
# tool_coursearchiver -> /admin/tool/coursearchiver


# php_extension	yaml Für STACK wird die Installation der YAML-Bibliothek empfohlen.
# php_extension	mbstring muss installiert und aktiviert sein

# Dependencies for qtype_stack
# qbehaviour_adaptivemultipart (2020103000) Fehlend Verfügbar Plugin-Info -> /question/behaviour/adaptivemultipart
# qbehaviour_dfexplicitvaildate (2018080600) Fehlend Verfügbar Plugin-Info -> /question/behaviour/qbehaviour_dfexplicitvaildate
# qbehaviour_dfcbmexplicitvaildate (2018080600) Fehlend Verfügbar Plugin-Info -> /question/behaviour/qbehaviour_dfcbmexplicitvaildate

