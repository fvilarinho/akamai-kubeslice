#!/bin/bash

# Checks the dependencies of this script.
function checkDependencies() {
  export KUBECONFIG=$1

  if [ -z "$KUBECONFIG" ]; then
    echo "The kubeconfig is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Fetches the node balancers.
function fetchNodeBalancers() {
  # Waits until all node balancers is ready.
  NAMESPACE=kubeslice-controller

  while true; do
    # Fetches the primary node balancer.
    HOSTNAME=$($KUBECTL_CMD get service kubeslice-ui-proxy \
                            -n "$NAMESPACE" \
                            -o jsonpath='{.status.loadBalancer.ingress[].hostname}')

    IP=$($KUBECTL_CMD get service kubeslice-ui-proxy \
                      -n "$NAMESPACE" \
                      -o jsonpath='{.status.loadBalancer.ingress[].ip}')

    if [ -n "$HOSTNAME" ] && [ -n "$IP" ]; then
      NODEBALANCER_ID=$($LINODE_CLI_CMD nodebalancers list --json | $JQ_CMD ".[]|select(.hostname == \"$HOSTNAME\")|.id")

      if [ -n "$NODEBALANCER_ID" ]; then
        break
      fi
    fi

    sleep 1
  done

  # Returns the fetched hostnames.
  echo "{\"id\": \"$NODEBALANCER_ID\", \"hostname\": \"$HOSTNAME\", \"ip\": \"$IP\"}"
}

# Main function.
function main() {
  checkDependencies "$1" "$2"
  fetchNodeBalancers
}

main "$1" "$2"