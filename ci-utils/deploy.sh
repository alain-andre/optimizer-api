#!/usr/bin/env bash
slack(){
  curl=$(curl --request POST --url "https://slack.com/api/chat.postMessage?token=${SLACK_TOKEN}&channel=${1}" \
    --header 'content-type: multipart/form-data;'  \
    --form text="${2}" \
    --form mrkdwn='true')
}

# Test if resque has no woring worker (0 of 5 Workers Working)
resque=$(curl -u ${USER}:${RESQUE_PWD} https://resque.rentokil-initial.mapotempo.com/working)

if [[ $resque == *"0 of 5 Workers Working"* ]]; then
  echo "Deploy : 0 of 5 Workers Working, we start deployment !!"
  slack CC47KJR5X "Deployment of the new image: no worker was found on the Initial server, delivery has started." # optim
  slack C4BDXG8JW "Deployment of the new image: no worker was found on the Initial server, delivery has started." # system

  if [[ "$CI_COMMIT_REF_NAME" == "beta" ]]; then
    portainer_url=https://portainer-beta.mapotempo.com/api/webhooks/
  else
    portainer_url=https://portainer.mapotempo.com/api/webhooks/
  fi

  hooks=(${HOOK_INITIAL_API} ${HOOK_INITIAL_DEFAULT} ${HOOK_INITIAL_WEB})
  for hook in "${hooks[@]}"
  do
    status=$(curl -o /dev/null -s -w "%{http_code}\n" -X POST ${portainer_url}${hook})
    echo $status
    if [[ $status != "204" ]]; then
      echo "Deploy : Hook (${hook}) is not anymore valid (status $status) ! Check project settings"
      slack C4BDXG8JW "Deploy : Hook (${hook}) is not anymore valid (status $status)! Check project settings" # system
      exit 1
    fi
  done
else
  echo "Deploy : Workers are currently running, deployment must be done by a human !"
  slack CC47KJR5X "Deployment of the new image: Workers are currently running, deployment must be done by a human !" # optim
  echo $Deploy : resque
  exit 1
fi
