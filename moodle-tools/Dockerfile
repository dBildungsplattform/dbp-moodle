FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
# Install like in moodle (Same php version required) https://github.com/bitnami/containers/blob/main/bitnami/moodle/4.1/debian-12/Dockerfile

RUN set -x \
    && apt-get -y update \
    && apt-get -y install wget python3-pip \
    && wget https://dl.k8s.io/release/v1.28.7/bin/linux/amd64/kubectl \
    && chmod +x kubectl \
    && mv ./kubectl /usr/local/bin/kubectl \
    && wget -qO /usr/share/keyrings/postgres.asc https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    && echo "deb [signed-by=/usr/share/keyrings/postgres.asc] https://apt.postgresql.org/pub/repos/apt jammy-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && wget https://downloads.bitnami.com/files/stacks/php/8.1.30-0/bitnami-php-8.1.30-0-linux-x64.tar.gz \
    && tar -xzf bitnami-php-8.1.30-0-linux-x64.tar.gz -C /opt \
    && apt-get -y update \
    && apt-get -y install \
        python3-boto3 \
        curl \
        duply \
        ca-certificates \
        gnupg \
        apt-transport-https \
        postgresql-client-16 \
        mariadb-client \
    && apt-get clean -y