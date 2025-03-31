#!/bin/bash

# Shows the labels.
function showLabel() {
  if [[ "$0" == *"undeploy.sh"* ]]; then
    echo "** Undeploy **"
  elif [[ "$0" == *"deploy.sh"* ]]; then
    echo "** Deploy **"
  fi
}

# Prepares the environment to execute this script.
function prepareToExecute() {
  ENV_FILENAME=$(pwd)/etc/demo/.env

  if [ -e "$ENV_FILENAME" ]; then
    source "$ENV_FILENAME"
  fi

  # Required binaries
  export TERRAFORM_CMD=$(which terraform)
  export HELM_CMD=$(which helm)
  export KUBECTL_CMD=$(which kubectl)
  export LINODE_CLI_CMD=$(which linode-cli)
  export AZ_CLI_CMD=$(which az)
  export JQ_CMD=$(which jq)
  export CERTBOT_CMD=$(which certbot)
  export HTPASSWD_CMD=$(which htpasswd)
}

# Shows the banner.
function showBanner() {
  # Checks if the banner file exists.
  if [ -f banner.txt ]; then
    cat banner.txt
  fi

  showLabel
}

prepareToExecute