# https://github.com/bitnami/containers/blob/main/bitnami/moodle/5.0/debian-12/rootfs/opt/bitnami/scripts/php-env.sh

# moodlehq/moodle-php-apache:8.1-bookworm enables new ways to configure php
# As a lightweight alternative to a full PHP configuration file, you can specify a set of prefixed environment variables when starting your container with these variables turned into ini-format configuration.
# Any environment variable whose name is prefixed with PHP_INI- will have the prefix removed, and will be added to a new ini file before the main command starts.
# The Problem si that the moodlehq image does not use php-fpm as bitnami
# active configuration
# php --ini
# php -i