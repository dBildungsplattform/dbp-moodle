# This Dockerfile starts the entrypoint script to evaluate if a new moodle version exists and an update should be started.
# To start an upgrade: Update the base image to the new version AND update the exact version in format "x.x.x" as argument in the ENTRYPOINT
FROM bitnami/moodle:4.1.0-debian-11-r15
RUN echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
USER root

COPY entrypoint.sh entrypoint.sh
RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh", "4.4.0"]
