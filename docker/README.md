# OpenClinica Docker


## Summary
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Utilities](#utilities)
- [Notes](#notes)


## Introduction
This directory is a Docker project intended to simplify the setup of one or 
more OpenClinica instances. The main components are:
- ```oc1```: a full OpenClinica instance for managing research data.
  + OpenClinica 3.7.
  + OpenClinica-ws 3.7.
  + Tomcat 7.
  + OpenJDK 7.
  + PostgreSQL 8.4.
- ```httpd```: webserver, for handling HTTPS connections and forwarding requests.
  + Apache httpd 2.4.
  

## Prerequisites
Follow the current instructions for installing Docker and Docker-Compose for 
your OS. This project was developed using Docker 1.9, Docker-Compose 1.5.0, 
Ubuntu 14.04, with 2vCPUs, 4GB RAM, and 10GB storage.

At the time of writing, the Docker installation instructions include some 
optional steps for adding your OS user to the docker group and configuring swap 
space, both of which are recommended. 


## Getting Started
This section assumes you're setting up a new instance. See later sections on 
backup and restore for how to migrate an existing OpenClinica instance.

The Docker-compose 1.5.0 release has experimental support for the Docker 1.9 
networking features. The ```up``` commands in this section have the 
```--x-networking``` flag to enable these features, which replace container 
linking.


### Basic
If you are trying out OpenClinica, or using it on your local machine only.
- Make a copy of this repository.
- In ```./oc1/docker-compose.yml```, uncomment the settings where indicated.
- From ```./oc1```, run ```docker-compose --x-networking up```.
  + OpenClinica will be at ```http://127.0.0.1:8080/OpenClinica```.
  + OpenClinica-ws will be at ```http://127.0.0.1:8081/OpenClinica-ws```.


### Advanced
If you are deploying OpenClinica on the Internet for other people to access.
- Make a copy of this repository.
- Update settings as follows.
  + ```./httpd/conf/httpd.conf```. At about line 90, 4 files required for TLS 
    are named. Obtain these files and put them under ```httpd/conf/cert```.
  + ```./oc1/docker-envs.env```. Update the settings as per the instructions in 
    the file.
  + ```./oc1/tomcat/conf/openclinica/datainfo.properties```. Add your settings 
    for email, LDAP and/or any other minor tweaks. Settings with a value of 
    "replacedbydocker" are overwritten at container startup. 
- (Optional) update any other settings as required.
  + All files in ```./oc1/tomcat/conf/``` are added to ```$CATALINA_HOME/conf```.
  + All "*.conf" files in ```./oc1/postgres/docker-entrypoint-initdb.d``` are 
    added to ```$PGDATA```.
- From ```./oc1```, run ```docker-compose --x-networking up```.
- Start the httpd container. 
  + TODO: elaborate on the required "net" settings so httpd can see oc1.


### Duplication
If you require more than one OpenClinica instance.
- Follow the Advanced setup steps to configure httpd and OpenClinica.
- Copy the ```oc1``` folder and rename it, e.g. to ```oc2```.
- Update ```docker-envs.env``` as per the instructions in the file.
- From ```./oc2```, run ```docker-compose --x-networking up```.
- Copy ```./httpd/conf/vhosts/default/apps/oc1.conf``` and rename it, e.g. to
  ```oc2.conf```.
- Update the above ```oc2.conf``` such that:
  + The ```Location``` for each app uses a path that is not currently in use 
    for that virtual host, e.g. ```/OpenClinica2```  and ```/OpenClinica-ws2```.
  + The ProxyPass and ProxyPassReverse hostnames to match the folder name from 
    above, e.g. ```oc2_ocweb_1``` and ```oc2_ocws_1```.
- Restart the httpd container.
  + TODO: elaborate on the required "net" settings so httpd can see oc2.


## Configuration
This section describes the configuration templates in more detail.


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
The current configuration is HTTP only, assuming httpd is handling the HTTPS 
connections. If the Tomcat instances are on a different machine to httpd, make 
the following changes to allow Tomcat to handle HTTPS.
- Add a HTTPS Connector element to ```server.xml``` with the desired settings.
- Change the exposed port in the tomcat/Dockerfiles to match the Connector's 
  port (probably 443).
- Include the keystore file in ```tomcat/conf/tomcat``` (same directory as 
  ```server.xml```), so that it is copied into ```$CATALINA_HOME/conf``` during 
  the container image build.
- Update the ProxyPass and ProxyPassReverse directives in
  ```./httpd/conf/vhosts/default/apps/oc1.conf``` to https.
- Restart, rebuild or restore the tomcat services and httpd.


#### OpenClinica
The main files for configuration are as follows
- ```datainfo.properties```: the main configuration. This template includes 
  some settings with a value ```replacedbydocker```, which will be replaced 
  during container startup. Email SMTP/S settings should be added to this file.
- ```extract.properties```: extract processing. This has no customisation 
  from the default and is provided only because OpenClinica expects it to be 
  present during startup.


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
  + TODO: update with instructions using Docker 1.9 volume management commands


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


### Connecting to a Container
To get inside a container to look around, use the following command:
```docker exec -it container_name bash```.
- If you want to check processes using ```top``` and it doesn't work, set
  ```export TERM=xterm``` after connecting, then re-run top.
- If you want to use psql in the postgres container, use the following command: 
  ```docker exec -it container_name gosu postgres psql```. This runs an 
  interactive terminal with psql running as the container's postgres superuser.


### Startup Times
On first run, the container images are built. This may take a while as a few 
hundred MB of base images are downloaded.

On each container creation, the container image is rebuilt, starting at the 
first "ADD" step, to ensure that the latest files are in the image. This may 
take a minute or two.

On container startup, Tomcat deploys the OpenClinica applications. This may 
take about a minute.

On running a restore script, the container data is updated to match the 
provided data. As long as no configuration is changed, the container can stay 
up. This may take a few seconds.


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
