# OpenClinica Docker


## Getting Started
- Install docker, and docker-compose (see below).
- Copy this repo.
- Change into the directory where ```docker-compose.yml``` is.
- Change the passwords contained in ```docker-envs.env```.
- Run ```docker-compose up```

By default, OpenClinica will not be configured to send emails. See below for 
how to add your email settings. 

The postgres and tomcat resource settings assume there is about 2GB RAM 
available on the host system.


### Installing Prerequisites
Docker provide a script for installing docker on linux, which is a quick 
alternative to following the dozen or so manual steps. Either:
- ```curl -sSL https://get.docker.com/ | sh```
- ```wget -qO- https://get.docker.com/ | sh```

To install docker-compose, install python3 and pip, then use pip to install:
- For Ubuntu: ```apt-get install python3-pip```.
- ```pip3 install docker-compose```.


### Customisation
Any customisations should be done before building the images. Images are 
automatically built when the ```docker-compose up``` command is run.


#### Rebuilding
If a configuration needs to be changed, the images can be updated by running 
```docker-compose build service``` where ```service``` is the name of the 
service to rebuild (one of "ocpg", "ocweb", or "ocws"). 


#### Postgres
There are 2 files for customising Postgres.
- ```postgresql.conf```: the main postgres configuration.
- ```pg_hba.conf```: host-based authentication configuration.

Other files included are:
- ```openclinica.backup``` pg_dump of v3.7 database, so that the migrations can 
  be skipped. This speeds up startup significantly.
- ```s1_create_oc_user_and_db.sh```: create an openclinica database and user.
- ```s2_restore_database.sh```: performs a pg_restore using openclinica.backup.
- ```s3_copy_default_confs.sh```: moves the *.conf files into the postgres 
  data directory so they are used by postgres.


#### Tomcat
There are 2 files for customising Tomcat.
- ```catalina.properties```: Includes a non-default directive to skip TLD 
  scanning for the multitude of OpenClinica jars without any TLDs. This speeds 
  up startup time significantly.
- ```server.xml```: Disables shutdown port (kill instead), and autoDeploy. 


##### Configuring TLS
The current configuration is HTTP only, assuming another local webserver is 
terminating the TLS connection (e.g. Apache or Nginx). To let Tomcat handle 
these connections, make the following changes.
- Add a Connector element to ```server.xml``` with the desired settings.
- Change the port mapping in ```docker-compose.yml``` to map the new 
  Connector's port to the host.
- Include the keystore file in ```tomcat/conf/tomcat``` (same directory as 
  ```server.xml```), so that it is copied into ```$CATALINA_HOME/conf```.


#### OpenClinica
There are 2 files for customising OpenClinica. 
- ```datainfo.properties```: general configuration. In the template, all 
  settings with the value ```replacedbydocker``` will be overwritten during 
  container startup. This is where the email SMTP settings are added.
- ```extract.properties```: extract configuration. This has no customisation 
  from the default and is provided only because OpenClinica expects it to be 
  present during startup.


### Utils
There are a few utility scripts included in the ```utils``` directory.
- ```cleanup_volumes.py```: in docker < 1.9, there's not a easy way to make 
  sure that volumes are removed with their containers. This is to prevent data 
  loss but it also can make development a bit trickier. Docker-compose includes 
  all the dependencies for this script, so run it using 
  ```sudo python cleanup_volumes.py```.
- ```remove_composed.sh```: shortcut to shutdown and remove the composed 
  containers.
- ```remove_untagged.sh```: shortcut to remove images that don't have a tag. 
  This can happen when a container is rebuilt. Untagged images don't get used 
  by ```docker-compose up``` anymore, so they might as well be deleted.


### What Docker-compose does
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


### Connecting to a Service Container
- To get inside a container to look around or do backups:
  ```docker exec -it docker_ocweb_1 bash```
  + If you want to check processes using ```top``` and it doesn't work, set the 
    following environment variable after connecting, then re-run top.
    - ```export TERM=xterm```
    

### Backups
- Run pg_dump and save it to the host (can't use $OC_DATABASE here sadly):
  ```docker exec -it docker_ocpg_1 pg_dump -U postgres \ 
       --no-privileges --no-tablespaces "openclinica" > openclinica.backup

- TODO: get this part working OK
- Run tar to get an archive of logs.
  ```docker exec -it docker_ocpg_1 \ 
       "find /var/lib/postgresql/data/pg_log/* -mtime +1 | \
        xargs tar -czv --verify --remove-files" > pg_log_$(date --iso).log

- TODO: add backup of tomcat /ocdata and /logs
- TODO: restore procedure


### Doing psql things
- Check the postgres IPAddress: ```docker inspect docker_ocweb_1 | grep \"IPAddr```
- Connect to postgres: ```docker exec -it psql -h youripaddr -U postgres```
  