# This Dockerfile starts the entrypoint script to evaluate if a new moodle version exists and an update should be started.
FROM bitnami/moodle:4.1.5-debian-11-r18
RUN echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
USER root

COPY moodleUpdateCheck.sh /moodleUpdateCheck.sh
RUN chmod +x /moodleUpdateCheck.sh && \
apt-get update && apt-get install -y \
curl

ENTRYPOINT ["/moodleUpdateCheck.sh"]
