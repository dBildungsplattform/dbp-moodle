# This Dockerfile starts the entrypoint script to evaluate if a new moodle version exists and an update should be started.
FROM bitnami/moodle:4.1.5-debian-11-r18
RUN echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
USER root

COPY moodleUpdateCheck.sh /moodleUpdateCheck.sh
RUN chmod +x /moodleUpdateCheck.sh && \
apt-get update && apt-get upgrade -y && \
apt-get install -y curl gpg unzip && \
rm -rf /var/lib/apt/lists/*

RUN curl https://moodle.org/plugins/download.php/29895/moosh_moodle42_2023090700.zip -o moosh.zip && \
unzip moosh.zip -d moosh/ && \
mkdir /.moosh && \
chmod 774 /.moosh

ENTRYPOINT ["/moodleUpdateCheck.sh"]
