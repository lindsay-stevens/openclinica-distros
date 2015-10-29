#!/bin/bash
set -e

# Call this script like: restore_tomcat.sh docker_ocweb_1 /path/to/folder/ x
# Where "docker_ocpg_1" is the container name.
# Where /path/to/folder contains the directories to drop into $CATALINA_HOME;
# - This may include one or both of the data and config directories.
# - For Openclinica: data dir: /ocdata and config dir: /openclinica.config
# - For Openclinica-ws: data dir: /ocdata and config dir: /openclinica-ws.config
# - A /webapps folder may also be included, if a new copy needs to be deployed.
# Where "x" prevents restart; if ommited the container will be restarted.
# - Restart will put the correct database configs into datainfo.properties.

# Restore openclinica data and config into $CATALINA_HOME and restart tomcat.
#
# Steps:
# - Copy backup directory from host into container.
# - Copy backup files into $CATALINA_HOME.
# - Set permissions on copied files so tomcat can work with them.
# - Remove the backup directory.
# - Restart the container if there are only 2 positional parameters given.
docker cp $2 $1:/tmp/oc_restore
docker exec $1 bash -c 'cp -R /tmp/oc_restore/* $CATALINA_HOME; \
    chown -R tomcat:tomcat $CATALINA_HOME; \
    chmod g+s $CATALINA_HOME; \
    chmod -R 775 $CATALINA_HOME; \
    rm -rf /tmp/oc_restore'
if [ $# -eq 2 ]; then
    docker restart $1
fi
