#!/bin/bash
set -o xtrace

# build and package idart
cd ../
ant clean build prepareLibs jar -Ddatabase.name=idart -Ddatabase.host=idart-postgres

cd docker
docker-compose -f docker-compose-idart.yml build
