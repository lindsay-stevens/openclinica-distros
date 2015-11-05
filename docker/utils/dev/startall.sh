docker network create composenet
cd $1
cd httpd
docker run -d -p 8080:443 -v $(pwd)/conf:/usr/local/apache2/conf --net="composenet" httpd:2.4
cd $1
cd oc1
docker-compose --x-networking up -d ocpg
sleep 10
docker-compose --x-networking up -d ocweb
sleep 10
docker-compose --x-networking up -d ocws
