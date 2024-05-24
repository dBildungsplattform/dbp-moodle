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

printf "=== Starting bitnami entrypoint ===\n"
if [ -d "/bitnami/moodle/" ]; then
    /bin/cp -p /moodleconfig/config.php /bitnami/moodle/config.php
    /bin/cp /moodleconfig/php.ini /opt/bitnami/php/etc/conf.d/php.ini
    /opt/bitnami/scripts/moodle/entrypoint.sh "/opt/bitnami/scripts/moodle/run.sh"
else 
    echo "=== Fresh install, starting bitnami/moodle first, then copying our config ==="
    /opt/bitnami/scripts/moodle/entrypoint.sh "/opt/bitnami/scripts/moodle/run.sh"
    sleep 30
    /bin/cp -p /moodleconfig/config.php /bitnami/moodle/config.php
    /bin/cp /moodleconfig/php.ini /opt/bitnami/php/etc/conf.d/php.ini
fi
