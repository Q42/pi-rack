#!/bin/bash
#set -e

source ./constants.sh
folderPath=$1


if [ -z "$azp_url" ]; then
  echo 1>&2 "error: missing azp_url environment variable"
  exit 1x
fi

if [ -z "$azp_token_file" ]; then
  if [ -z "$azp_token" ]; then
    echo 1>&2 "error: missing azp_token environment variable"
    exit 1
  fi

  # rm -r $folderPath/ 2> /dev/null

  # mkdir $folderPath/azp/

  azp_token_file=$folderPath/azp/.token
  touch $azp_token_file
  
  echo -n $azp_token > "$azp_token_file"
fi

unset azp_token

if [ -n "$azp_work" ]; then
  mkdir -p "$azp_work"
fi

mkdir $folderPath/agent
cd $folderPath/agent

export AGENT_ALLOW_RUNASROOT="1"

cleanup() {
  if [ -e config.sh ]; then
    print_header "Cleanup. Removing Azure Pipelines agent..."

    ./config.sh remove --unattended \
      --auth PAT \
      --token $(cat "$azp_token_file")
  fi
}

print_header() {
  lightcyan='\033[1;36m'
  nocolor='\033[0m'
  echo -e "${lightcyan}$1${nocolor}"
}

# Let the agent ignore the token env variables
export VSO_AGENT_IGNORE=azp_token,azp_token_file

print_header "1. Determining matching Azure Pipelines agent..."

azp_agent_response=$(curl -LsS \
  -u user:$(cat "$azp_token_file") \
  -H 'Accept:application/json;api-version=3.0-preview' \
  "$azp_url/_apis/distributedtask/packages/agent?platform=linux-arm64")

if echo "$azp_agent_response" | jq . >/dev/null 2>&1; then
  azp_agentpackage_url=$(echo "$azp_agent_response" \
    | jq -r '.value | map([.version.major,.version.minor,.version.patch,.downloadUrl]) | sort | .[length-1] | .[3]')
fi
echo "package url $azp_agentpackage_url"
if [ -z "$azp_agentpackage_url" -o "$azp_agentpackage_url" == "null" ]; then
  echo 1>&2 "error: could not determine a matching Azure Pipelines agent - check that account '$azp_url' is correct and the token is valid for that account"
  exit 1
fi

print_header "2. Downloading and installing Azure Pipelines agent..."

curl -LsS $azp_agentpackage_url | tar -xz & wait $!

source ./env.sh

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

print_header "3. Configuring Azure Pipelines agent..."

./config.sh --unattended \
  --agent "${azp_agent_name:-$(hostname)}" \
  --url "$azp_url" \
  --auth PAT \
  --token $(cat "$azp_token_file") \
  --pool "${azp_pool:-Default}" \
  --work "${azp_work:-_work}" \
  --replace \
  --acceptTeeEula & wait $!

# remove the administrative token before accepting work
rm $azp_token_file