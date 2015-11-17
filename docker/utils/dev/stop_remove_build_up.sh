docker-compose stop
docker-compose rm -fv
docker-compose build
docker-compose --x-networking up -d
