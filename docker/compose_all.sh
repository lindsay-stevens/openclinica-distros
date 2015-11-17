#!/bin/bash
set -e

# Issue docker-compose commands to all subprojects.

if [ "$#" -eq 0 ]; then
    # Usage info
    echo "***** Usage"
    echo "Parameter 1: where to look for docker-compose.yml files."
    echo " - project name to target, or 'all' for all projects."
    echo "Parameter 2: docker-compose command {new|upd|stop|...}."
    echo " - new -> create new containers (--x-networking up -d)."
    echo " - upd -> start existing (--x-networking up -d --no-recreate)."
    echo " - stop or any other command -> passed to docker-compose as-is."
    echo " - commands with flags must be in quotes."
    echo "*****"
    exit 1
fi


# Parameter 1: where to look for docker-compose.yml files.
if [ "$1" == "all" ]; then
    search="."
else
    search="$1"
fi

# Parameter 2: docker-compose command {new|upd|stop|...}.
case $2 in
    new)
        cmd="--x-networking up -d"
        ;;
    upd)
        cmd="--x-networking up -d --no-recreate"
        ;;
    *)
        cmd="$2"
esac

# Make sure the 'common' network exists so containers can see eachother.
if docker network ls | grep common; then
    echo "Docker network 'common' exists, skipping."
else
    echo "Creating docker network 'common'."
    docker network create common
fi

# For each compose project, issue the provided command.
find $search -name docker-compose.yml -exec sh -c "export COMPOSE_FILE={}; docker-compose $cmd" \;

