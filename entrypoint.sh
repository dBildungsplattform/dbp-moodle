#!/bin/bash
set -e

if ! /moodleUpdateCheck.sh 2>&1 | tee -a "/bitnami/moodledata/moodleUpdateCheck.log"; then
    echo "moodleUpdateCheck script exited with error. Check /bitnami/moodledata/moodleUpdateCheck.log"
fi
wait $!

# move config files and start bitnami entrypoint
/bin/cp -p /moodleconfig/config.php /bitnami/moodle/config.php
/bin/cp /moodleconfig/php.ini /opt/bitnami/php/etc/conf.d/php.ini
/opt/bitnami/scripts/moodle/entrypoint.sh "/opt/bitnami/scripts/moodle/run.sh"