#!/bin/bash

# https://github.com/bitnami/containers/blob/main/bitnami/moodle/5.0/debian-12/rootfs/opt/bitnami/scripts/postgresql-client/setup.sh

set -o errexit
set -o nounset
set -o pipefail

. /scripts/liblog.sh    # TODO should work by importing into the entrypoint, but seems to have some issues?

. /scripts/libpostgresqlclient.sh

# Load PostgreSQL Client environment variables
. /scripts/init/postgres/postgres-client-env.sh

# Execute the main function:
postgresql_client_validate

postgresql_client_initialize