#!/bin/bash
set -e

printf "=== Starting moodleUpdateCheck ===\n"
if ! /moodleUpdateCheck.sh 2>&1 | tee -a "/bitnami/moodledata/moodleUpdateCheck.log"; then
    printf "=== moodleUpdateCheck failed! ===\n"
    printf "Check /bitnami/moodledata/moodleUpdateCheck.log\n"
else
    printf "=== moodleUpdateCheck finished ===\n"
fi

wait $!
# move config files and start bitnami entrypoint
/bin/cp -p /moodleconfig/config.php /bitnami/moodle/config.php
/bin/cp /moodleconfig/php.ini /opt/bitnami/php/etc/conf.d/php.ini
printf "=== Starting bitnami entrypoint ===\n"
/opt/bitnami/scripts/moodle/entrypoint.sh "/opt/bitnami/scripts/moodle/run.sh"