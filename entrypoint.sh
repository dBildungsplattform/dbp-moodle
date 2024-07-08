#!/bin/bash
set -e

printf "=== Starting moodleUpdateCheck ===\n"

/moodleUpdateCheck.sh 2>&1 | tee -a "/bitnami/moodledata/moodleUpdateCheck.log"
EXIT_CODE=${PIPESTATUS[0]}


if [ $EXIT_CODE -eq 0 ]; then
    printf "=== moodleUpdateCheck finished ===\n"
else
    printf "=== moodleUpdateCheck failed! ===\n"
    printf "Check /bitnami/moodledata/moodleUpdateCheck.log\n"
fi

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
    touch /bitnami/moodledata/FreshInstall
    wait
fi
