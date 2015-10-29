#!/bin/bash
set -e

# Call this script like: restore_postgres.sh docker_ocpg_1 /path/to/folder/ x
# Where "docker_ocpg_1" is the container name.
# Where /path/to/folder contains the configs to drop into $PGDATA, and backup file.
# - The configs may include postgresql.conf, pg_hba.conf, pg_ident.conf.
# - The backup file should be named openclinica.backup.
# Where "x" prevents restart; if ommited the container will be restarted.

# Restore a pg_dump custom format file into a postgres container.
#
# Steps:
# - Copy backup directory from host into container.
# - Copy backup files into $PGDATA.
# - Give ownership of backup file to container postgres user.
# - Restore the backup into postgres.
# - Remove the backup directory.
# - Restart the container if there are only 2 positional parameters given.
docker cp $2 $1:/tmp/pg_restore
docker exec $1 bash -c 'chown -R postgres /tmp/pg_restore; \
    chmod -R 700 /tmp/pg_restore; \
    export PGPASSWORD="$POSTGRES_PASSWORD"; \
    gosu postgres pg_restore -U "$POSTGRES_USER" -d "$OC_DATABASE" -Ocw \
    --role="$OC_USER" -j 4 -F c /tmp/pg_restore/openclinica.backup; \
    cp /tmp/pg_restore/*.conf $PGDATA; \
    chown postgres $PGDATA/*.conf; \
    chmod 700 $PGDATA/*.conf; \
    rm -rf /tmp/pg_restore'
if [ $# -eq 2 ]; then
    docker restart $1
fi
