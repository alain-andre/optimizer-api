#!/usr/bin/env bash

docker build -t registry.test.com/mapotempo/optimizer-api:latest -f docker/Dockerfile --build-arg ORTOOLS_VERSION=v7.0 --build-arg VROOM_VERSION=v1.2.0 --build-arg OPTIMIZER_ORTOOLS_VERSION=${OPTIMIZER_ORTOOLS_VERSION:-latest} .

mkdir -p ./redis

docker swarm init
docker stack deploy -c ./docker/travis-dc.yml optimizer

TEST_ENV='TRAVIS=true COV=false SKIP_DICHO=true SKIP_JSPRIT=true SKIP_REAL_CASES=true SKIP_SCHEDULING=true SKIP_SPLIT_CLUSTERING=true'

TEST_LOG_LEVEL='info'
TEST_COVERAGE='false'
DOCKER_SERVICE_NAME=optimizer_api
CONTAINER=${DOCKER_SERVICE_NAME}.1.$(docker service ps -f "name=${DOCKER_SERVICE_NAME}.1" ${DOCKER_SERVICE_NAME} -q --no-trunc | head -n1)

while true;
do
  STATE=$(docker ps | grep ${CONTAINER})
  if [ -n "${STATE}" ]; then break; fi
  echo "Setting up services..."

  sleep 1
done

echo "Docker services state:"
docker service ps --no-trunc ${DOCKER_SERVICE_NAME}
docker ps
docker logs ${CONTAINER}

echo "Setting image configuration to enable tests"
docker exec -i ${CONTAINER} apt update -y > /dev/null
docker exec -i ${CONTAINER} apt install git -y > /dev/null
docker exec -i ${CONTAINER} rm /srv/app/.bundle/config
docker exec -i ${CONTAINER} bundle install
docker exec -i ${CONTAINER} bundle exec rake test ${TEST_ENV}
