#!/bin/bash

# Checks the dependencies of this script.
function checkDependencies() {
  export KUBECONFIG=$1

  if [ -z "$KUBECONFIG" ]; then
    echo "The kubeconfig is not defined! Please define it first to continue!"

    exit 1
  fi
}

function prepareToExecute() {
  source ../functions.sh
}

# Fetches the worker node IP.
function fetch() {
  while true; do
    IP=$($KUBECTL_CMD get nodes -o wide | grep Ready | head -n 1 | awk -F' ' '{print $7}')

    if [[ $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
      break
    fi

    sleep 1
  done

  echo "{\"ip\": \"$IP\"}"
}

# Main function.
function main() {
  prepareToExecute
  checkDependencies "$1"
  fetch
}

main "$1"