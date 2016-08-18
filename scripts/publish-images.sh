#!/bin/bash
set -o xtrace

# Log in to the Bintray Docker registry
docker login -u $BINTRAY_USER -p $BINTRAY_API_KEY -e $BINTRAY_EMAIL esaude-docker-idart-docker.bintray.io

# Tag the java image
docker tag `docker images -q docker_idart-java` esaude-docker-idart-docker.bintray.io/java:$TRAVIS_TAG

# Push the tomcat image
docker push esaude-docker-idart-docker.bintray.io/java:$TRAVIS_TAG

# Tag the postgres image
docker tag `docker images -q docker_idart-postgres` esaude-docker-idart-docker.bintray.io/postgres:$TRAVIS_TAG

# Push the postgres image
docker push esaude-docker-idart-docker.bintray.io/postgres:$TRAVIS_TAG
