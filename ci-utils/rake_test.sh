#!/bin/sh

if [[ $CI_COMMIT_REF_NAME == "master" ]]; then
  REF_NAME=ce
else
  REF_NAME=${CI_COMMIT_REF_NAME}
fi
docker pull $REGISTRY_URL/$USER-${REF_NAME}/$CI_PROJECT_NAME:latest || true

export ROUTER_API_KEY=${ROUTER_API_KEY}
export ROUTER_URL=${ROUTER_URL}

docker swarm init
mkdir -p ./redis
docker stack deploy -c ./docker/docker-compose.yml optimizer
CONTAINER=${DOCKER_SERVICE_NAME}.1.$(docker service ps -f "name=${DOCKER_SERVICE_NAME}.1" ${DOCKER_SERVICE_NAME} -q --no-trunc | head -n1)

while true;
do
  STATE=$(docker ps | grep ${CONTAINER})
  if [ -n "${STATE}" ]; then break; fi
  sleep 1
done

docker exec -i ${CONTAINER} apt update -y > /dev/null
docker exec -i ${CONTAINER} apt install git -y > /dev/null
docker exec -i ${CONTAINER} rm /srv/app/.bundle/config
docker exec -i ${CONTAINER} bundle install
docker exec -i ${CONTAINER} bundle exec rake test
