#!/bin/bash
mkdir /plugins

curl https://github.com/h5p/moodle-mod_hvp/archive/refs/tags/1.26.1.zip -o /plugins/mod_hvp.zip
curl https://github.com/Wunderbyte-GmbH/moodle-mod_booking/archive/refs/tags/v8.2.4-stable.zip -o /plugins/mod_booking.zip
curl https://github.com/moodleworkplace/moodle-tool_certificate/archive/refs/tags/v4.4.1.zip -o /plugins/tool_certificate.zip