# OpenClinica Docker


## Summary
- [Introduction](#introduction)
- [Getting Started](#getting-started)
- [Prerequisites(#prerequisites)
- [Customisation](#customisation)
- [What Docker-compose does](#what-docker-compose-does)
- [Connecting to a Container](#connecting-to-a-container)
- [Utilities](#utilities)


## Introduction
This directory is a docker-compose project that provisions docker containers 
to simplify the setup of an OpenClinica instance. This includes:
- A postgresql container with an empty OpenClinica database.
- A tomcat container with OpenClinica.
- (Optional) A tomcat container with OpenClinica-ws.

This may be useful for routine setup of OpenClinica instances, or for creating 
a consistent environment for running tests. 

The major versions currently in the stack are:
- OpenClinica 3.7.
- OpenJDK JRE 7.
- Tomcat 7.
- PostgreSQL 8.4.

For production deployments, a separate web server container should be created. 
This server should handle TLS connections, and reverse proxy requests to the 
OpenClinica instance(s).

TODO: figure this out and add a section about it.


## Getting Started
- Obtain a 64 bit Linux virtual machine that is compatible with docker.
- Install docker and docker-compose.
- Make a copy of this repository for each instance required.
- Change into the directory where ```docker-compose.yml``` is.
- Change the passwords contained in ```docker-envs.env```.
- Run ```docker-compose up```

By default, OpenClinica will not be configured to send emails. See below for 
how to add your email settings. 

TODO: add link to instructions

The postgres and tomcat resource settings assume there is about 2GB RAM 
available on the host system. Ideally it also has 2vCPUs or more, but 1 is OK.


## Prerequisites
Docker provide a script for installing docker on linux, which is a quick 
alternative to following the dozen or so manual steps. Either:
- ```curl -sSL https://get.docker.com/ | sh```
- ```wget -qO- https://get.docker.com/ | sh```

To install docker-compose, install python3 and pip, then use pip to install:
- For Ubuntu: ```apt-get install python3-pip```.
- ```pip3 install docker-compose```.


## Customisation
TODO: rewrite this referring to alternative pathway with restore scripts.

Any customisations should be done before building the images. Images are 
automatically built when the ```docker-compose up``` command is run.


### Rebuilding
If a configuration needs to be changed, the images can be updated by running 
```docker-compose build service``` where ```service``` is the name of the 
service to rebuild (one of "ocpg", "ocweb", or "ocws"). 


### Postgres
There are 2 files for customising Postgres.
- ```postgresql.conf```: the main postgres configuration.
- ```pg_hba.conf```: host-based authentication configuration.

Other files included are:
- ```openclinica.backup``` pg_dump of v3.7 database, so that the migrations can 
  be skipped. This speeds up startup significantly. Replace this with a backup 
  from another existing database to use it as a starting point instead.
- ```s1_create_oc_user_and_db.sh```: create an openclinica database and user.
- ```s2_restore_database.sh```: performs a pg_restore using openclinica.backup.
- ```s3_copy_default_confs.sh```: moves the *.conf files into the postgres 
  data directory so they are used by postgres.


### Tomcat
There are 2 files for customising Tomcat.
- ```catalina.properties```: Includes a non-default directive to skip TLD 
  scanning for the multitude of OpenClinica jars without any TLDs. This speeds 
  up startup time significantly.
- ```server.xml```: Disables shutdown port (kill instead), and autoDeploy. 


#### Configuring TLS
The current configuration is HTTP only, assuming another local webserver is 
terminating the TLS connection (e.g. Apache or Nginx). To let Tomcat handle 
these connections, make the following changes.
- Add a Connector element to ```server.xml``` with the desired settings.
- Change the port mapping in ```docker-compose.yml``` to map the new 
  Connector's port to the host.
- Include the keystore file in ```tomcat/conf/tomcat``` (same directory as 
  ```server.xml```), so that it is copied into ```$CATALINA_HOME/conf```.


### OpenClinica
There are 2 files for customising OpenClinica. 
- ```datainfo.properties```: general configuration. In the template, all 
  settings with the value ```replacedbydocker``` will be overwritten during 
  container startup. This is where the email SMTP settings are added.
- ```extract.properties```: extract configuration. This has no customisation 
  from the default and is provided only because OpenClinica expects it to be 
  present during startup.


## What Docker-compose does
There are many guides online but here is a short version of what happens in the 
background when ```docker-compose up``` is run.
- Pull required container images from dockerhub (busybox, tomcat, debian).
- Build the container images for each service (ocweb, ocws, ocpg).
  - Image names will be prefixed with the folder name, e.g. ```docker_ocweb``
- Create a data container for each service.
- Mount the respective data container volume(s) in their service container.
  - Volumes allow data to be shared between containers, provide a way to keep 
    data so it's not included in the container image. Files not in a volume 
    are deleted when a container is deleted.
- Start each container.
- After startup, services will be available as follows.
  + OpenClinica web interface: http://localhost:8080/OpenClinica
  + OpenClinica soap web service: http://localhost:8081/OpenClinica-ws


## Connecting to a Container
To get inside a container to look around, use the following command:
```docker exec -it docker_ocweb_1 bash```.
- If you want to check processes using ```top``` and it doesn't work, set
  ```export TERM=xterm``` after connecting, then re-run top.
- If you want to use psql in the postgres container, use the following command: 
  ```docker exec -it docker_ocpg_1 gosu postgres psql```. This runs an 
  interactive terminal with psql running as the container's postgres superuser.


## Utilities
The ```utils``` directory contains scripts relating to the following task 
types, described below:
- Dev(elopment)
- Backup
- Restore

All scripts assume that they are being run from the context of the project, 
i.e. the folder that has ```docker-compose.yml``` in it.


### Development
These scripts can be useful when setting up containers with the desired 
configuration.
- ```remove_composed.sh```: shutdown and remove containers created by compose.
- ```remove_untagged.sh```: remove container images that don't have a tag.
  This can happen when a container is rebuilt. Untagged images don't get used 
  by ```docker-compose up``` anymore, so they might as well be deleted.
- ```cleanup_volumes.py```: remove volumes no longer associated with any 
  container. Docker will not automatically remove volumes when a container is 
  removed, on the fair assumption that the volume data is important.


### Backups
These can be useful for backing up application state.
- ```backup_postgres.sh```: copies an archive of a database pg_dump, config, 
  and logs to a folder at ```./backups/[container_name]```.
  
TODO: update script to include the $PGDATA/*.conf files.

  + Script parameters:
    - Container name.
- ```backup_tomcat.sh```: creates an of the app data, config, and logs, plus 
  the tomcat logs, to a folder at ```./backups/[container_name]```
  + Script parameters:
    - Container name.
    
TODO: update script to include $CATALINA_HOME/conf files & reverse for restore.


### Restore
These can be useful for restoring application state.
- ```restore_postgres.sh```: restores a pg_dump into the database, optionally 
  copying configuration files into ```$PGDATA``` which may include 
  ```postgresql.conf```,  ```pg_hba.conf```, and ```pg_ident.conf```.
  + Script parameters:
    - Container name.
    - Path to folder with pg_dump named ```openclinica.backup``` and configs.
    - Optional "x" flag to prevent restarting the container.
- ```restore_tomcat.sh```: copies included folders into ```$CATALINA_HOME```, 
  which may include openclinica app data ```ocdata```, openclinica 
  configuration ```openclinica[-ws].config```, and application code 
  ```webapps/OpenClinica[-ws]```.
  + Script parameters:
    - Container name.
    - Path to folder with folders to copy into ```$CATALINA_HOME```.
    - Optional "x" flag to prevent restarting the container.
