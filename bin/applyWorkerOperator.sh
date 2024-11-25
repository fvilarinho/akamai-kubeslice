#!/bin/bash

# Check the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The kubeconfig filename is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$MANIFEST_FILENAME" ]; then
    echo "The manifest filename is not defined! Please define it first to continue!"

    exit 1
  fi
}

function applyWorkerOperator() {
  NAMESPACE=kubeslice-system

  NAMESPACE_EXISTS=$($KUBECTL_CMD get ns | grep "$NAMESPACE")

  if [ -z "$NAMESPACE_EXISTS" ]; then
    $HELM_CMD install kubeslice-worker \
                      kubeslice/kubeslice-worker \
                      -f "$MANIFEST_FILENAME" \
                      -n "$NAMESPACE" \
                       --create-namespace
  fi
}

# Main function.
function main() {
  checkDependencies
  applyWorkerOperator
}

main