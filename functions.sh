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
  # Required binaries
  export TERRAFORM_CMD=$(which terraform)
  export HELM_CMD=$(which helm)
  export KUBECTL_CMD=$(which kubectl)
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