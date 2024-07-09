#!/bin/bash
cd /plugins
php /moosh/moosh.php plugin-list

# Dependencies
php /moosh/moosh.php plugin-download -v 4.1 local_wunderbyte_table # Dependency of mod_booking
php /moosh/moosh.php plugin-download -v 4.1 theme_boost # Dependency of theme_boost_union
php /moosh/moosh.php plugin-download -v 4.1 tool_certificate # Dependency of mod_coursecertificate

# Plugins
php /moosh/moosh.php plugin-download -v 4.1 mod_etherpadlite
php /moosh/moosh.php plugin-download -v 4.1 mod_hvp
php /moosh/moosh.php plugin-download -v 4.1 mod_groupselect
php /moosh/moosh.php plugin-download -v 4.1 mod_jitsi
php /moosh/moosh.php plugin-download -v 4.1 mod_pdfannotator
php /moosh/moosh.php plugin-download -v 4.1 mod_skype
php /moosh/moosh.php plugin-download -v 4.1 mod_zoom
php /moosh/moosh.php plugin-download -v 4.1 mod_booking
php /moosh/moosh.php plugin-download -v 4.1 mod_reengagement
php /moosh/moosh.php plugin-download -v 4.1 mod_unilabel
php /moosh/moosh.php plugin-download -v 4.1 mod_geogebra
php /moosh/moosh.php plugin-download -v 4.1 format_remuiformat
php /moosh/moosh.php plugin-download -v 4.1 format_tiles
php /moosh/moosh.php plugin-download -v 4.1 format_topcoll
php /moosh/moosh.php plugin-download -v 4.1 auth_oidc
php /moosh/moosh.php plugin-download -v 4.1 auth_saml2
php /moosh/moosh.php plugin-download -v 4.1 block_dash
php /moosh/moosh.php plugin-download -v 4.1 block_sharing_cart
php /moosh/moosh.php plugin-download -v 4.1 block_xp
php /moosh/moosh.php plugin-download -v 4.1 mod_coursecertificate
php /moosh/moosh.php plugin-download -v 4.1 theme_boost_union