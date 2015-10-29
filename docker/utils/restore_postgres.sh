#!/bin/bash
set -e

# Call this script like: backup_postgres.sh docker_ocpg_1 /path/to/file.backup
# Where "docker_ocpg_1" is the container name.

# Create a new directory with the same name as the container argument.
mkdir -p backups/$1
cd backups/$1

# Restore a pg_dump custom format file into a postgres container.
#
# Steps:
# - Copy backup file from host into container.
# - Give ownership of backup file to container postgres user.
# - Restore the backup into postgres.
# - Remove the backup file.
docker cp $2 $1:/tmp/pg_restore.backup
docker exec $1 bash -c 'chown -R postgres /tmp/pg_restore.backup; \
    chmod 700 /tmp/pg_restore.backup; \
    export PGPASSWORD="$POSTGRES_PASSWORD"; \
    gosu postgres pg_restore -U "$POSTGRES_USER" -d "$OC_DATABASE" -Ocw \
    --role="$OC_USER" -j 4 -F c /tmp/pg_restore.backup; \
    rm /tmp/pg_restore.backup'