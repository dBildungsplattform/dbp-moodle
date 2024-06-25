# This Dockerfile starts the entrypoint script to evaluate if a new moodle version exists and an update should be started.
FROM bitnami/moodle:4.1.11-debian-12-r0
RUN echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
USER root

COPY entrypoint.sh /entrypoint.sh
COPY moodleUpdateCheck.sh /moodleUpdateCheck.sh
RUN chmod +x /entrypoint.sh /moodleUpdateCheck.sh && \
apt-get update && apt-get upgrade -y && \
apt-get install -y curl gpg unzip autoconf php-dev php-redis && \
rm -rf /var/lib/apt/lists/*

COPY phpRedisInstall.sh /tmp/phpRedisInstall.sh
RUN chmod +x /tmp/phpRedisInstall.sh
RUN /tmp/phpRedisInstall.sh

RUN curl -L https://github.com/tmuras/moosh/archive/refs/tags/1.14.tar.gz -o moosh.tar.gz && \
mkdir moosh/ && tar -xzvf moosh.tar.gz -C moosh/ --strip-components=1 && \
mkdir /.moosh && \
chmod 774 /.moosh &&\
cd /moosh/ && \
composer install

ENTRYPOINT ["/entrypoint.sh"]
