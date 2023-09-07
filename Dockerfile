# This Dockerfile starts the entrypoint script to evaluate if a new moodle version exists and an update should be started.
FROM bitnami/moodle:4.2.2-debian-11-r18
RUN echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
USER root

COPY moodleUpdateCheck.sh /moodleUpdateCheck.sh
RUN chmod +x /moodleUpdateCheck.sh && \
apt-get update && apt-get install -y \
curl gpg

RUN apt-get -y install software-properties-common && \
apt-add-repository ppa:zabuch/ppa && \
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CA1F0167ECFEA950 && \
apt-get update && \
apt-get -y install moosh

ENTRYPOINT ["/moodleUpdateCheck.sh"]
