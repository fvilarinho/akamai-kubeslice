#!/bin/bash

# Check the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The kubeconfig is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$CLUSTER_NODES" ]; then
    echo "The cluster nodes are not defined! Please define them first to continue!"

    exit 1
  fi

  if [ -z "$TAGS" ]; then
    echo "The tags are not defined! Please define them first to continue!"

    exit 1
  fi
}

# Prepare the environment to execute the script.
function prepareToExecute() {
  export TAGS_PARAMS=

  for TAG in $TAGS
  do
    TAGS_PARAMS="$TAGS_PARAMS --tags $TAG"
  done
}

# Applies the tags in node balancers.
function applyTagsInNodeBalancers() {
  echo "Applying tags in node balancers..."

  NODE_BALANCERS_IPS=$($KUBECTL_CMD get svc -A | grep LoadBalancer | awk -F' ' '{print $5}')

  for NODE_BALANCER_IP in $NODE_BALANCERS_IPS
  do
    NODE_BALANCER_ID=$($LINODE_CLI_CMD nodebalancers list --ipv4 $NODE_BALANCER_IP --json | $JQ_CMD -r '.[].id')

    if [ -n "$NODE_BALANCER_ID" ]; then
      eval "$LINODE_CLI_CMD nodebalancers update $TAGS_PARAMS $TAG_PARAMS $NODE_BALANCER_ID > /dev/null"
    fi
  done
}

# Applies the tags in cluster nodes.
function applyTagsInClusterNodes() {
  echo "Applying tags in cluster nodes..."

  for CLUSTER_NODE in $CLUSTER_NODES
  do
    eval "$LINODE_CLI_CMD linodes update $TAGS_PARAMS $CLUSTER_NODE > /dev/null"

    VOLUMES=$($LINODE_CLI_CMD volumes list --json | $JQ_CMD ".[]|select(.linode_id == $CLUSTER_NODE)|.id")

    for VOLUME in $VOLUMES
    do
      eval "$LINODE_CLI_CMD volumes update $TAGS_PARAMS $VOLUME > /dev/null"
    done
  done
}

# Main function.
function main() {
  checkDependencies
  prepareToExecute
  applyTagsInClusterNodes
  applyTagsInNodeBalancers
}

main