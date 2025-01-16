#!/bin/bash

download_kaltura() {
    local target_version="$1"
    latest_tag="$(curl -s https://api.github.com/repos/kaltura/moodle_plugin/releases | jq -r '.[].tag_name' | grep "$target_version" | head -1)"
    echo "latest_tag: ${latest_tag}"
    latest_zip_url="$(curl -s https://api.github.com/repos/kaltura/moodle_plugin/releases | jq -r ".[] | select(.tag_name == \"${latest_tag}\") | .assets[].browser_download_url")"
    echo "latest_zip_url: ${latest_zip_url}"
    curl -L -o kaltura.zip "$latest_zip_url"
}

major_minor="${MOODLE_VERSION%.*}"

cd /plugins || exit 1

#download_kaltura "$major_minor"
moosh plugin-list > /dev/null

# Dependencies
moosh plugin-download -v "$major_minor" local_wunderbyte_table # Dependency of mod_booking
moosh plugin-download -v "$major_minor" tool_certificate # Dependency of mod_coursecertificate

# Plugins
moosh plugin-download -v "$major_minor" mod_etherpadlite
moosh plugin-download -v "$major_minor" mod_hvp
#moosh plugin-download -v "$major_minor" mod_groupselect
moosh plugin-download -v "$major_minor" mod_jitsi
moosh plugin-download -v "$major_minor" mod_pdfannotator
moosh plugin-download -v "$major_minor" mod_skype
moosh plugin-download -v "$major_minor" mod_zoom
moosh plugin-download -v "$major_minor" mod_booking
#moosh plugin-download -v "$major_minor" mod_reengagement
moosh plugin-download -v "$major_minor" mod_unilabel
moosh plugin-download -v "$major_minor" mod_geogebra
moosh plugin-download -v "$major_minor" mod_choicegroup
moosh plugin-download -v "$major_minor" local_staticpage
#moosh plugin-download -v "$major_minor" tool_heartbeat
moosh plugin-download -v "$major_minor" format_remuiformat
moosh plugin-download -v "$major_minor" format_tiles
moosh plugin-download -v "$major_minor" format_topcoll
moosh plugin-download -v "$major_minor" format_flexsections
moosh plugin-download -v "$major_minor" format_multitopic
moosh plugin-download -v "$major_minor" auth_oidc
moosh plugin-download -v "$major_minor" auth_saml2
moosh plugin-download -v "$major_minor" block_dash
moosh plugin-download -v "$major_minor" block_sharing_cart
moosh plugin-download -v "$major_minor" block_xp
moosh plugin-download -v "$major_minor" mod_coursecertificate
moosh plugin-download -v "$major_minor" theme_adaptable
moosh plugin-download -v "$major_minor" theme_boost_union
moosh plugin-download -v "$major_minor" theme_boost_magnific
#moosh plugin-download -v "$major_minor" theme_snap