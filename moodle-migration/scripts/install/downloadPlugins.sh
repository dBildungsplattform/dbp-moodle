#!/bin/bash

major_minor="${MOODLE_VERSION%.*}"

cd /plugins || exit 1

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
moosh plugin-download -v "$major_minor" local_staticpage
moosh plugin-download -v "$major_minor" format_remuiformat
moosh plugin-download -v "$major_minor" format_tiles
moosh plugin-download -v "$major_minor" format_topcoll
moosh plugin-download -v "$major_minor" format_flexsections
moosh plugin-download -v "$major_minor" format_multitopic
moosh plugin-download -v "$major_minor" auth_oidc
moosh plugin-download -v "$major_minor" block_xp
moosh plugin-download -v "$major_minor" mod_coursecertificate
moosh plugin-download -v "$major_minor" theme_adaptable
moosh plugin-download -v "$major_minor" theme_boost_union
moosh plugin-download -v "$major_minor" theme_boost_magnific
moosh plugin-download -v "$major_minor" tool_usersuspension
moosh plugin-download -v "$major_minor" tool_dynamic_cohorts
