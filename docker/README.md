# OpenClinica Docker


## Getting Started
- Install docker, docker-compose
- Change into directory with "docker-compose.yml"
- Run ```docker-compose up``

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
- Check the postgres IPAddress: ```docker inspect docker_ocweb_1 | grep \"IPAddr``
- Connect to postgres: ```docker exec -it psql -h youripaddr -U postgres```
  