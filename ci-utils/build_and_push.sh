#!/usr/bin/env bash

echo $CI_COMMIT_REF_NAME
if [ "$CI_COMMIT_REF_NAME" == "beta" ] || [ "$CI_COMMIT_REF_NAME" == "prod" ] || [ "$CI_COMMIT_REF_NAME" == "prod-initial" ]; then
  if [ "$CI_COMMIT_REF_NAME" == "prod-initial" ]; then
    REF_NAME=prod
  else
    REF_NAME=${CI_COMMIT_REF_NAME}
  fi
else
  REF_NAME=ce
fi

NAMESPACE=$USER-${REF_NAME}
IMAGE_NAME=$REGISTRY_URL/$NAMESPACE/$PROJECT_NAME

docker pull $REGISTRY_URL/$USER-${REF_NAME}/$CI_PROJECT_NAME:latest || true

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

docker build --cache-from $IMAGE_NAME:latest -f ${DOCKER_FILE} -t $IMAGE_NAME:latest --build-arg VROOM_VERSION=${VROOM_VERSION} --build-arg OPTIMIZER_ORTOOLS_VERSION=${OPTIMIZER_ORTOOLS_VERSION} --build-arg REGISTRY=${REGISTRY_URL}/ .

# Pushing a branch
if [ "$CI_COMMIT_REF_NAME" == "master" ] || [ "$CI_COMMIT_REF_NAME" == "beta" ] || [ "$CI_COMMIT_REF_NAME" == "prod" ]; then
  docker push $IMAGE_NAME:latest
  docker push $IMAGE_NAME:previous
else # pushing a TAG
  TAG=${CI_COMMIT_REF_NAME}
  echo "Managing tag ${TAG} for REPOSITORY_ID: ${REPOSITORY_ID}"

  if [[ -n $REPOSITORY_ID ]]; then
    echo "Testing if tag exists"
    RESULT=$(curl -sX GET --header 'Accept: application/json' \
      --header "Portus-Auth: mapotempo:${PORTUS_TOKEN}" \
      https://portus.mapotempo.com/api/v1/repositories/${REPOSITORY_ID}/tags/ | \
      jq '.[] | "\(.name)"' | \
      grep ${TAG})
    echo RESULT: ${RESULT}

    if [[ -n $RESULT ]]; then
      echo "$IMAGE_NAME:${TAG} exists, saving old tag"
      docker pull $IMAGE_NAME:${TAG}
      docker tag $IMAGE_NAME:${TAG} $IMAGE_NAME:${TAG}-old
      docker push $IMAGE_NAME:${TAG}-old
    fi
  fi

  # push new tag
  set -e
  docker tag $IMAGE_NAME:latest $IMAGE_NAME:${TAG}
  docker push $IMAGE_NAME:${TAG}
fi
