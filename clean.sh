#!/bin/bash
docker-compose \
    -f ./docker-compose.yml \
    -f ./docker-compose.lx.yml \
    -f ./docker-compose.microsites.yml \
    down \
    --remove-orphans \
&& docker volume prune -f \
&& rm -Rf \
    ./.logs \
    ./wp-container \
    ./wp-container-lx \
    ./wp-container-microsites \
;
