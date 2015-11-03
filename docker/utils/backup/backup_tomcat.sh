#!/bin/bash
set -e

# Call this script like: backup_tomcat.sh docker_ocweb_1
# Where "docker_ocweb_1" is the container name.

# Create a new directory with the same name as the container argument.
mkdir -p backups/$1
cd backups/$1

# Backup the tomcat openclinica data files and logs.
#
# Steps:
# - Create backup archive and tmp directories.
# - Make sure the tmp directory is clean, and move into it.
# - Copy all the ocdata files into the tmp directory.
# - Find all log files older than today, and move them into the tmp folder.
# - Copy all the conf files into the tmp directory.
# - Put the tmp files in a tar.gz file.
# - Clean out the tmp directory.
docker exec -it $1 bash -c 'cd $CATALINA_HOME/backups; mkdir -p archives tmp; \
    rm -rf $CATALINA_HOME/backups/tmp/* ; cd tmp; mkdir -p ocdata logs; \
    cp -R $CATALINA_HOME/ocdata . ; \
    OC_APP_LC="$(tr '[:upper:]' '[:lower:]' <<<"$OC_APP")" ; \
    cp -R $CATALINA_HOME/$OC_APP_LC.config . ; \
    cp -R $CATALINA_HOME/conf . ; \
    find $CATALINA_HOME/logs -type f -daystart -mtime +0 -exec mv {} . \; ;\
    tar cfz $CATALINA_HOME/backups/archives/tomcat_$(date --iso).tar.gz . ;\
    rm -rf $CATALINA_HOME/backups/tmp/*'

# Copy the backup archives to the directory created at the start of the script.
docker run -it --rm --volumes-from $1 -v $(pwd):/backups busybox \
   find /usr/local/tomcat/backups/archives -type f -exec mv {} /backups +
   
   
