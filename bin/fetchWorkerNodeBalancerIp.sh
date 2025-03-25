#!/bin/bash

# Checks the dependencies of this script.
function checkDependencies() {
  export KUBECONFIG=$1

  if [ -z "$KUBECONFIG" ]; then
    echo "The kubeconfig is not defined! Please define it first to continue!"

    exit 1
  fi

  export INGRESS=$2

  if [ -z "$INGRESS" ]; then
    echo "The ingress is not defined! Please define it first to continue!"

    exit 1
  fi
}

function prepareToExecute() {
  source ../functions.sh
}

# Fetches the worker node balancer IP.
function fetch() {
  NAMESPACE=$INGRESS

  while true; do
    IP=$($KUBECTL_CMD get svc -n $NAMESPACE | grep LoadBalancer | awk -F' ' '{print $4}')

    if [ -n "$IP" ]; then
      break
    fi

    sleep 1
  done

  echo "{\"ip\": \"$IP\"}"
}

# Main function.
function main() {
  prepareToExecute
  checkDependencies "$1" "$2"
  fetch
}

main "$1" "$2"