FROM bitnami/moodle:4.0.5-debian-11-r6
RUN echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
