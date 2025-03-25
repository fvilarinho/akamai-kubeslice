#!/bin/bash

# Checks the dependencies of this script.
function checkDependencies() {
  export KUBECONFIG=$1

  if [ -z "$KUBECONFIG" ]; then
    echo "The kubeconfig is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Fetches the worker IPs.
function fetch() {
  while true; do
    IP=$($KUBECTL_CMD get nodes -o wide | grep Ready | head -n 1 | awk -F' ' '{print $7}')

    if [ -n "$IP" ]; then
      break
    fi

    sleep 1
  done

  echo "{\"ip\": \"$IP\"}"
}

# Main function.
function main() {
  checkDependencies "$1"
  fetch
}

main "$1"