#!/bin/bash

# Checks the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
  echo "kubeconfig is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$MANIFEST_FILENAME" ]; then
    echo "The manifest file is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Prepares the environment to execute this script.
function prepareToExecute() {
  source ../../functions.sh
}

# Applies the manifest.
function apply() {
  $KUBECTL_CMD apply -f "$MANIFEST_FILENAME"
}

# Main function.
function main () {
  prepareToExecute
  checkDependencies
  apply
}

main
