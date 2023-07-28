# This Dockerfile starts the entrypoint script to evaluate if a new moodle version exists and an update should be started.
ARG new_image_version="0.0.0"

FROM bitnami/moodle:4.1.0-debian-11-r15
RUN echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
ARG new_image_version=$APP_VERSION
ENTRYPOINT ["echo $APP_VERSION"]

FROM ubuntu:22.10
USER root
ARG new_image_version

COPY moodleUpdateCheck.sh /moodleUpdateCheck.sh
RUN chmod +x /moodleUpdateCheck.sh

ENTRYPOINT ["/moodleUpdateCheck.sh"]
