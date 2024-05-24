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
if [[ -f /bitnami/moodle/version.php && -d "/bitnami/moodle/" && -d "/opt/bitnami/php/etc/conf.d/" ]]; then
    printf "=== Starting bitnami/moodle entrypoint ===\n"
    /bin/cp -p /moodleconfig/config.php /bitnami/moodle/config.php
    /bin/cp /moodleconfig/php.ini /opt/bitnami/php/etc/conf.d/php.ini
    /opt/bitnami/scripts/moodle/entrypoint.sh "/opt/bitnami/scripts/moodle/run.sh"
else 
    printf "=== Fresh install. starting bitnami/moodle first, then copying our config ===\n"
    /opt/bitnami/scripts/moodle/entrypoint.sh "/opt/bitnami/scripts/moodle/run.sh" &
    sleep 30
    /bin/cp -p /moodleconfig/config.php /bitnami/moodle/config.php
    /bin/cp /moodleconfig/php.ini /opt/bitnami/php/etc/conf.d/php.ini
    wait
fi
