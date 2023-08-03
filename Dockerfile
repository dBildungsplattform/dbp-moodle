# This Dockerfile starts the entrypoint script to evaluate if a new moodle version exists and an update should be started.
FROM bitnami/moodle:4.1.0-debian-11-r15
RUN echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
USER root

COPY moodleUpdateCheck.sh /moodleUpdateCheck.sh
RUN chmod +x /moodleUpdateCheck.sh
#&& \
#apt-get update && apt-get install -y \
#curl gpg


#RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null && \
#apt-get install apt-transport-https --yes && \
#echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
#apt-get update && \
#apt-get -y install helm && \
#helm repo add bitnami https://charts.bitnami.com/bitnami

ENTRYPOINT ["/moodleUpdateCheck.sh"]
