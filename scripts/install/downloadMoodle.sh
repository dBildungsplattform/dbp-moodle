#!/bin/bash
image_version="$MOODLE_VERSION"

# alternative download urls
# https://packaging.moodle.org/stable${stable_version}/moodle-${cur_image_version}.tgz"
# https://download.moodle.org/download.php/direct/stable${stable_version}/moodle-${cur_image_version}.tgz

curl "https://github.com/moodle/moodle/archive/refs/tags/v${image_version}.tar.gz" -o "/moodle-${image_version}.tgz"