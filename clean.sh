#!/bin/bash
docker-compose down --remove-orphans &&
docker volume prune &&
rm -Rf ./wp-container

