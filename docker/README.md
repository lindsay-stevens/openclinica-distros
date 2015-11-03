# OpenClinica Docker


## Summary
- [Introduction](#introduction)
- [Getting Started](#getting-started)
- [Prerequisites](#prerequisites)
- [Customisation](#customisation)
- [What Docker-compose does](#what-docker-compose-does)
- [Connecting to a Container](#connecting-to-a-container)
- [Utilities](#utilities)
- [Notes](#notes)


## Introduction
This directory is a docker-compose project that provisions docker containers 
to simplify the setup of an OpenClinica instance. This includes:
- A postgresql container with an empty OpenClinica database (ocpg).
- A tomcat container with OpenClinica (ocweb).
- (Optional) A tomcat container with OpenClinica-ws (ocws).

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
how to customise the container settings.

The template postgres and tomcat resource settings assume there is about 2GB 
RAM or more available on the host system. Ideally it has 2vCPUs or more, and 
disk space of about 10GB or more.


## Prerequisites
Docker provide a script for installing docker on linux, which is a quick 
alternative to following the dozen or so manual steps. Either:
- ```curl -sSL https://get.docker.com/ | sh```
- ```wget -qO- https://get.docker.com/ | sh```

To install docker-compose, install python3 and pip, then use pip to install:
- For Ubuntu: ```apt-get install python3-pip```.
- ```pip3 install docker-compose```.


## Customisation
It is possible to customise the container configurations either before or after 
building the container images. The first time ```docker-compose up``` is run, 
the container images will be built if they don't already exist.

The pre-build and post-build strategies are described below.


### Post-build
This is useful if trying this deployment method for the first time, or if 
migrating an existing OpenClinica instance to docker. It involves creating the 
containers, then running the ```utils/restore``` scripts for postgres and 
tomcat to replace the template data and configurations.


### Pre-Build
This is useful if deploying the same or similar configuration many times, or if 
the configuration is unlikely to change. It involves editing the configuration 
files for each container before building the image.


#### Postgres
The main files for configuration are as follows.
- ```postgresql.conf```: the main configuration. This template includes larger 
  memory allowances than the default, and specifies that log data is written in 
  the CSV format in daily files under  ```$PGDATA/pg_log```.
- ```pg_hba.conf```: host-based authentication and protocol control. This 
  template allows unencrypted password-based connections from the local machine 
  or a private network address. This is to allow other containers on the same 
  host to connect. This should not be a problem if the port is not mapped to 
  the host container, and the host container does not expose port 5432.
- (Optional) ```pg_ident.conf```: user or group mapping.

Other files included are as follows.
- ```openclinica.backup```: pg_dump of OpenClinica v3.7 database, so that the 
  first-time database structure migrations can be skipped. Replace this with a 
  backup from another existing database to use it as a starting point instead; 
  any necessary migrations will be run on startup.
- ```s1_create_oc_user_and_db.sh```: creates an openclinica database and user.
- ```s2_restore_database.sh```: performs a pg_restore using the above 
  ```openclinica.backup.``` file.
- ```s3_copy_default_confs.sh```: moves the ```*.conf``` files into the 
  postgres data directory so they are used by postgres.


#### Tomcat
The main files for configuration are as follows.
- ```catalina.properties```: class loading and other configuration. This 
  template includes directives to skip TLD scanning for the multitude of 
  OpenClinica jars without any TLDs, which speeds up startup time significantly.
- ```server.xml```: connections configuration. This template defines only one 
  http connection, disables the shutdown port (process kill'ed instead), 
  and disables automatic .WAR unpacking and deployment.


##### Configuring Tomcat HTTPS
The current configuration is HTTP only, assuming another local webserver is 
terminating the TLS connection (e.g. Apache or Nginx). To let Tomcat handle 
these connections, make the following changes.
- Add a HTTPS Connector element to ```server.xml``` with the desired settings.
- Change the exposed port in ```docker-compose.yml``` or the Dockerfiles to 
  match the Connector's port (probably 443).
- Include the keystore file in ```tomcat/conf/tomcat``` (same directory as 
  ```server.xml```), so that it is copied into ```$CATALINA_HOME/conf``` during 
  the container image build.


#### OpenClinica
The main files for configuration are as follows
- ```datainfo.properties```: the main configuration. This template includes 
  some settings with a value ```replacedbydocker```, which will be replaced 
  during container startup. Email SMTP/S settings should be added to this file.
- ```extract.properties```: extract processing. This has no customisation 
  from the default and is provided only because OpenClinica expects it to be 
  present during startup.


## What Docker-compose does
There are many guides online but here is a short version of what happens in the 
background when ```docker-compose up``` is run.
- Pull required container images from dockerhub (busybox, tomcat, debian).
- Build the container images for each service (ocweb, ocws, ocpg).
  - Image names will be prefixed with the folder name, e.g. ```docker_ocweb```
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
```docker exec -it container_name bash```.
- If you want to check processes using ```top``` and it doesn't work, set
  ```export TERM=xterm``` after connecting, then re-run top.
- If you want to use psql in the postgres container, use the following command: 
  ```docker exec -it container_name gosu postgres psql```. This runs an 
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
- ```backup_postgres.sh```: copies an archive of a database pg_dump, config
  files, and logs to a folder at ```./backups/container_name```.
  + Script parameters:
    - Container name.
- ```backup_tomcat.sh```: creates an of the app data, config, and logs, plus 
  the tomcat logs, to a folder at ```./backups/container_name```
  + Script parameters:
    - Container name.


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
  configuration ```openclinica[-ws].config```, application code 
  ```webapps/OpenClinica[-ws]```, and tomcat configurations ```conf```.
  + Script parameters:
    - Container name.
    - Path to folder with folders to copy into ```$CATALINA_HOME```.
    - Optional "x" flag to prevent restarting the container.


## Notes


### Fixing Storage Issues
While trying to get the Dockerfiles right, a lot of container / volume creation 
and removal goes on. The 8GB storage for the Virtualbox VM I was using resulted 
in a small-ish amount of space for Docker, after 4GB being consumed by swap 
space there was 4GB available for Docker.

By default Docker sets up a root loopback file system logical volume mount.
This jargon more or less means:
- root: like the Windows ```C:/``` drive, the topmost directory.
- loopback: like an upwards symbolic link or shortcut, e.g. /this/path -> /this.
- file system: some method of managing files.
- logical volume: some space for files that may or may not be the same as the 
  space physically available on a drive.
- mount: a connection to a place to send files.

The logical volume can get filled up with docker images and volumes. Once full, 
the containers may stop working because they have no space, or no free inodes.

To check the currently available space:
- ```sudo pvs```: physical volume space.
- ```sudo lvs```: logical volume space.
- ```sudo df -h```: filesystem space, or ```sudo df -i``` for inodes statistics.

To provision more space, the following steps worked:
- Shutdown the VM.
- Use VBoxManage to resize the disk for the VM to 10GB.
  ```VBoxManage modifyhd "/path/to/vdi_or_vdmk_file" --resize 10000MB```
- Download a copy of the gparted live CD ISO and mount it as a VM optical disk.
  + It's possible to use CLI instead, but using a live CD removes the problems
    around trying to change a filesystem volume that's currently mounted.
- Start the VM and extend the partition into the new space (in my case, ~+2GB).
- Shutdown the VM and remove the gparted ISO.
- Expand the physical volume into the new space: ```sudo pvresize /dev/sda5```.
- Check the available physical volume space: ```sudo pvs```.
- Expand the logical volume by a small amount less than the available space 
  shown in the pvs output for "PFree" (if it is too big it won't mount): 
  ```sudo lvresize -L +1.8GB /dev/mapper/docker--vg-root```.
- Expand the filesystem: ```sudo resize2fs /dev/mapper/docker--vg-root```.

Checking the physical, logical and filesystem stats again should show that the 
new space is available to use.

While researching this solution for Ubuntu, I came across a lot of guides 
related to fixing the storage setup in CentOS. These issue seemed to stem from 
CentOS not supporting Docker's preferred file system flavour, called "aufs".
