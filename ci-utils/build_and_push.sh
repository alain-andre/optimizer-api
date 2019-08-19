#!/usr/bin/env bash
if [[ $CI_COMMIT_REF_NAME == "master" ]]; then
  REF_NAME=ce
else
  REF_NAME=${CI_COMMIT_REF_NAME}
fi

OPTIMIZER_ORTOOLS_VERSION=latest
NAMESPACE=$USER-${REF_NAME}

docker pull $REGISTRY_URL/$USER-${REF_NAME}/$CI_PROJECT_NAME:latest || true

TEST_GITHUB=${TEST_GITHUB:-0}
if [[ $TEST_GITHUB -eq 1 ]]; then # Must check github latest tag.
  TAG=$(git ls-remote --tags -t https://github.com/Mapotempo/$PROJECT_NAME.git | \
    awk '{print $2}' | grep v | tail -n 1 | cut -d '/' -f 3)
  echo TAG: ${TAG}
fi

NAMESPACE_ID=$(curl -sX GET --header 'Accept: application/json' \
  --header "Portus-Auth: mapotempo:${PORTUS_TOKEN}" \
  https://portus.mapotempo.com/api/v1/namespaces/ | \
  jq '.[] | " \(.id) \(.name)"' | \
  grep -e "${NAMESPACE}\"$" | \
  awk '{print $2}')
echo NAMESPACE_ID: ${NAMESPACE_ID}
if [[ -z $NAMESPACE_ID ]]; then exit 1; fi

REPOSITORY_ID=$(curl -sX GET --header 'Accept: application/json' \
  --header "Portus-Auth: mapotempo:${PORTUS_TOKEN}" \
  https://portus.mapotempo.com/api/v1/namespaces/${NAMESPACE_ID}/repositories/ | \
  jq '.[] | " \(.id) \(.name)"' | \
  grep ${PROJECT_NAME} | \
  awk '{print $2}')
echo REPOSITORY_ID: ${REPOSITORY_ID}

if [[ -z $REPOSITORY_ID ]]; then
  RESULT=$(curl -sX GET --header 'Accept: application/json' \
    --header "Portus-Auth: mapotempo:${PORTUS_TOKEN}" \
    https://portus.mapotempo.com/api/v1/repositories/${REPOSITORY_ID}/tags/ | \
    jq '.[] | "\(.name)"' | \
    grep ${TAG})
  echo RESULT: ${RESULT}
fi

set -e
IMAGE_NAME=$REGISTRY_URL/$NAMESPACE/$PROJECT_NAME
docker build --cache-from $IMAGE_NAME:latest -f ${DOCKER_FILE} -t $IMAGE_NAME:latest --build-arg ORTOOLS_VERSION=${ORTOOLS_VERSION} --build-arg VROOM_VERSION=${VROOM_VERSION} --build-arg OPTIMIZER_ORTOOLS_VERSION=${OPTIMIZER_ORTOOLS_VERSION} --build-arg REGISTRY=${REGISTRY_URL}/ --build-arg BRANCH=${REF_NAME} .
docker push $IMAGE_NAME:latest

if [[ $REF_NAME != "ce" ]]; then
  exit 0
fi

if [[ -z $RESULT ]]; then
  docker tag $IMAGE_NAME:latest $IMAGE_NAME:${TAG}
  docker push $IMAGE_NAME:${TAG}
else
  echo "$IMAGE_NAME:${TAG} exists, skipping push"
fi
