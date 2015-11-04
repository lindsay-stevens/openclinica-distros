#!/bin/bash
set -e

# Some convenient variables
OC_APP_LC="$(tr '[:upper:]' '[:lower:]' <<<"$OC_APP")"
OC_CONFIG=$CATALINA_HOME/$OC_APP_LC.config
OC_DATAINFO=$OC_CONFIG/datainfo.properties

# Function for finding / replace configuration key=value ($1=$2)
find_replace() {
    # Escape escapes, eos, and replace all: http://stackoverflow.com/a/270567
    key="$(echo "$1" | sed 's/[\/&]/\\&/g')"
    value="$(echo "$2" | sed 's/[\/&]/\\&/g')"
    sed -ri  "s/^#?($key\s*=\s*)\S+/\1"$value"/" "$OC_DATAINFO"
}


if [ "$*" = 'catalina.sh run' ]; then
    # Create the config dir if not already there and copy over templates.
    # Give ownership of $CATALINA_HOME to tomcat user and allow required access.
    if [ ! -d $OC_CONFIG ]; then
        mkdir -p $OC_CONFIG
        cp $CATALINA_HOME/docker/openclinica/* $OC_CONFIG
        chown -R tomcat:tomcat $CATALINA_HOME
        chmod g+s $CATALINA_HOME
        chmod -R 775 $CATALINA_HOME
    fi
    
    # These configs come from docker-compose so are unknown during build.
    # The variables are inserted to the datainfo.properties file.
    find_replace 'dbUser'   $OC_USER
    find_replace 'dbPass'   $OC_PASSWORD
    find_replace 'db'       $OC_DATABASE
    find_replace 'dbPort'   $OCPG_PORT
    find_replace 'dbHost'   $OCPG_HOST
    find_replace 'filePath' $CATALINA_HOME/ocdata/
    find_replace 'log.dir'  $CATALINA_HOME/logs/$OC_APP
    
    exec gosu tomcat "$@"
fi

exec "$@"