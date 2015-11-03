#!/bin/bash
set -e

# Call this script like: backup_postgres.sh docker_ocpg_1
# Where "docker_ocpg_1" is the container name.

# Create a new directory with the same name as the container argument.
mkdir -p backups/$1
cd backups/$1

# Backup the postgres openclinica database and log files.
#
# Steps:
# - Create backup archive and tmp directories.
# - Make sure the tmp directory is clean, and move into it.
# - Alias the docker postgres password so pg_dump doesn't prompt for it.
# - Run pg_dump of the openclinica database to a pg_dump custom file.
# - Find all log files older than today, and move them into the tmp folder.
# - Copy all *.conf files into the tmp folder.
# - Put the tmp files in a tar.gz file.
# - Clean out the tmp directory.
docker exec -it $1 bash -c 'mkdir -p $PGDATA/backups; cd $PGDATA/backups; \
    mkdir -p archives tmp; rm -f $PGDATA/backups/tmp/* ; cd tmp; \
    export PGPASSWORD=$POSTGRES_PASSWORD; \
    pg_dump -U $POSTGRES_USER -wx -F c --no-tablespaces \
    -f $OC_DATABASE-$(date --iso).backup $OC_DATABASE; \
    find $PGDATA/pg_log -type f -daystart -mtime +0 -exec mv {} . \; ; \
    cp $PGDATA/*.conf . ; \
    tar cfz $PGDATA/backups/archives/postgres_$(date --iso).tar.gz . ; \
    rm -f $PGDATA/backups/tmp/*'

# Copy the backup archives to the directory created at the start of the script.
docker run -it --rm --volumes-from $1 -v $(pwd):/backups busybox \
   find /var/lib/postgresql/data/backups/archives -type f -exec mv {} /backups +