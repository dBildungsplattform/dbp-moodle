#!/bin/bash
cd /plugins
php /moosh/moosh.php plugin-list
php /moosh/moosh.php plugin-download -v 4.1 mod_hvp
php /moosh/moosh.php plugin-download -v 4.2 mod_booking
php /moosh/moosh.php plugin-download -v 4.1 tool_certificate
php /moosh/moosh.php plugin-download -v 4.1 local_wunderbyte_table