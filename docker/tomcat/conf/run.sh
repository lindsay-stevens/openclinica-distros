#!/bin/bash

# These configs come from docker-compose so are unknown during build.

# Create the config dir if not already there and copy over templates.
OC_APP_LC="$(tr '[:upper:]' '[:lower:]' <<<"$OC_APP")"
if [ ! -d $CATALINA_HOME/$OC_APP_LC.config ]; then
    mkdir $CATALINA_HOME/$OC_APP_LC.config
    cp $CATALINA_HOME/docker/app/* $CATALINA_HOME/$OC_APP_LC.config
    OC_DATAINFO=$CATALINA_HOME/$OC_APP_LC.config/datainfo.properties
fi

# Substitute the variables into datainfo.properties.
# Using ocdata instead of OC_APP_LC for data so docker-compose.yml is simpler.
sed -i "/^dbUser=.*/c\dbUser=$OC_USER" $OC_DATAINFO
sed -i "/^dbPass=.*/c\dbPass=$OC_PASSWORD" $OC_DATAINFO
sed -i "/^db=.*/c\db=$OC_DATABASE" $OC_DATAINFO
sed -i "/^dbPort=.*/c\dbPort=$OCPG_PORT_5432_TCP_PORT" $OC_DATAINFO
sed -i "/^dbHost=.*/c\dbHost=$OCPG_PORT_5432_TCP_ADDR" $OC_DATAINFO
sed -i "/^filePath=.*/c\filePath=$CATALINA_HOME/ocdata/" $OC_DATAINFO
sed -i "/^log.dir=.*/c\log.dir=$CATALINA_HOME/ocdata/$OC_APP" $OC_DATAINFO

# Start up Tomcat.
exec $CATALINA_HOME/bin/catalina.sh run
