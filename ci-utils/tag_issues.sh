#!/usr/bin/env bash

MILESTONE=$(curl -sX GET --header 'Accept: application/json' \
  --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
  https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/milestones?state=active | \
  jq -r '.[] | "{\"due\": \"\(.due_date)\", \"title\": \"\(.title)\", \"id\": \(.id)}"' | \
  sort | \
  head -n 1)

CURRENT_MILESTONE_ID=$(jq -r '.id' <<< ${MILESTONE})
CURRENT_MILESTONE_LABEL=$(jq -r '.title' <<< ${MILESTONE})
DUE_DATE=$(jq -r '.due' <<< ${MILESTONE})
echo "CURRENT_MILESTONE_LABEL: ${CURRENT_MILESTONE_LABEL} (Fin au $DUE_DATE)"
if [[ -z $CURRENT_MILESTONE_ID ]]; then exit 1; fi

# Get all closed issues of the defined milestone
RESULT=$(curl -sX GET --header 'Accept: application/json' \
  --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
  https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/milestones/${CURRENT_MILESTONE_ID}/issues | \
  jq -r '.[] | select(.state=="closed") | "{\"iid\": \(.iid), \"state\": \"\(.state)\", \"labels\": \(.labels)}"')

echo "LABEL: $LABEL"
echo "RESULT: $RESULT"
set -e

# Update closed issues with the tag
IFS=$'\n'; list=($RESULT)
for item in "${list[@]}"; do
  echo "Treatment of ${item}"
  iid=$(jq -r '.iid' <<< ${item})
  labels="$(sed -r 's/\[|\]|,|"//g' <<< $(jq -r '.labels' <<< ${item})), $LABEL"
  list_labels=($labels)
  flat_labels=$(printf "%s," "${list_labels[@]}")

  echo "Tagging issue #${iid} with labels $flat_labels"
  echo "curl -sX PUT -H \"PRIVATE-TOKEN: $PRIVATE_TOKEN\" --data-urlencode \"labels=$flat_labels\" https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/issues/${iid} > /dev/null"
  curl -sX PUT -H "PRIVATE-TOKEN: $PRIVATE_TOKEN" --data-urlencode "labels=$flat_labels" https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/issues/${iid} > /dev/null
done
