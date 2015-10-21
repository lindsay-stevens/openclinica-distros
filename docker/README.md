# OpenClinica Docker


## Getting Started
- Install docker, docker-compose.
  + Complete the optional setup step of adding yourself to the docker group, or 
    prefix every docker command with ```sudo```.
- Change into the directory where ```docker-compose.yml``` is.
- Change the passwords contained in ```docker-envs.env```.
- Run ```docker-compose up```


### Customisation
Any customisations should be done before building the images. Images are 
automatically built when the ```up``` command is run.

#### Postgres
There are 2 files for customising postgres.
- ```postgresql.conf```: the main postgres configuration.
- ```pg_hba.conf```: host-based authentication configuration.

Other files included are:
- ```openclinica.backup``` pg_dump of v3.7 database, so that the lengthy 
  migrations steps are skipped.
- ```s1_create_oc_user_and_db.sh```: create an openclinica database and user.
- ```s2_restore_database.sh```: performs a pg_restore using openclinica.backup.
- ```s3_copy_default_confs.sh```: moves the *.conf files into the postgres 
  data directory so they are used by postgres.

#### Tomcat
There are 2 files for customising tomcat.
- ```catalina.properties```: Includes a non-default directive to skip TLD 
  scanning for the multitude of OpenClinica jars without any TLDs.
- ```server.xml```: Disables shutdown port (kill instead), and autoDeploy. If 
  no reverse proxy server is used, configure TLS:
  + Add a Connector element with the desired settings.

TODO: change back to subfolders for tomcat and OC so keystore / ssl files can be 
    added without having to update the dockerfile or entrypoint script.
  
There are 2 files for customising OpenClinica.
- ```datainfo.properties```: openclinica config. 

- TODO: some notes on changing passwords / customising configuration / rebuilding steps


### What happened
- Docker-compose does the following things.
  + Pull required images from dockerhub (busybox, tomcat, debian).
  + Build the images for each service (ocweb, ocws, ocpg)
    - Image names will be prefixed with the folder name, e.g. ```docker_ocweb``
  + Create a data container for each service.
  + Mount the respective data container volume(s) in their service container.
    - Volumes allow data to be shared between containers and avoid deletion.
  + Start each container.
- After startup, services will be available as follows.
  + OpenClinica web interface: http://localhost:8080/OpenClinica
  + OpenClinica soap web service: http://localhost:8081/OpenClinica-ws

### Notes
- The postgres process(es) runs as the user "postgres" with appropriate access.
- The tomcat process runs as the user "tomcat" with appropriate access.
- To get inside a container as root to look around or do backups:
  ```docker exec -it docker_ocweb_1 bash```
  + If you want to check processes using ```top``` and it doesn't work, set the 
    following environment variable first ```export TERM=xterm```.
    

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
  