#!/bin/bash

set -e
image_version="$MOODLE_VERSION"

# Download Moodle tarball
echo "Downloading Moodle version ${image_version}..."
wget "https://github.com/moodle/moodle/archive/refs/tags/v${image_version}.tar.gz" -O "/tmp/moodle-${image_version}.tgz"

# Extract to target path
echo "Extracting Moodle to ${MOODLE_PATH}..."
mkdir -p "$MOODLE_PATH"
tar -xzf "/tmp/moodle-${image_version}.tgz" --strip-components=1 -C "$MOODLE_PATH" --no-same-owner

echo "Moodle ${image_version} downloaded and extracted successfully."