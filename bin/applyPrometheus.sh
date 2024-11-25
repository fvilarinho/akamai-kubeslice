#!/bin/bash

# Check the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The kubeconfig filename is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies prometheus stack replacing the placeholders with the environment variables values.
function applyPrometheus() {
  NAMESPACE=monitoring

  NAMESPACE_EXISTS=$($KUBECTL_CMD get ns | grep "$NAMESPACE")

  if [ -z "$NAMESPACE_EXISTS" ]; then
    $HELM_CMD install prometheus \
                      kubeslice/prometheus \
                      -n "$NAMESPACE" \
                      --create-namespace
  fi
}

# Main function.
function main() {
  checkDependencies
  applyPrometheus
}

main