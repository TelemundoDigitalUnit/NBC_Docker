#!/bin/bash
docker-compose \
    -f docker-compose.yml \
    -f docker-compose.lx.yml \
    -f docker-compose.microsites.yml \
    $@ \
;
