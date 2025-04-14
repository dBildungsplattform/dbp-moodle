FROM docker.io/bitnami/minideb:bookworm

ARG DEBIAN_FRONTEND=noninteractive

RUN set -x \
    && apt-get -y update \
    && apt-get -y install wget python3-pip \
    && wget https://dl.k8s.io/release/v1.28.7/bin/linux/amd64/kubectl \
    && chmod +x kubectl \
    && mv ./kubectl /usr/local/bin/kubectl \
    && wget -qO /usr/share/keyrings/postgres.asc https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    && echo "deb [signed-by=/usr/share/keyrings/postgres.asc] https://apt.postgresql.org/pub/repos/apt jammy-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get -y update \
    && apt-get -y install \
        python3-boto3 \
        curl \
        ca-certificates \
        duply \
        gnupg \
        apt-transport-https \
        postgresql-client-16 \
        mariadb-client \
    && apt-get clean -y

# Set the environment variable
ENV PROFILE_DIR=/etc/duply/default
