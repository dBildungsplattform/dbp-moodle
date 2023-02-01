FROM bitnami/moodle:4.1.0-debian-11-r15
RUN echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
