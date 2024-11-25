#!/bin/bash

# Check the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The kubeconfig filename is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies istio stack replacing the placeholders with the environment variables values.
function applyIstio() {
  NAMESPACE=istio-system

  NAMESPACE_EXISTS=$($KUBECTL_CMD get ns | grep "$NAMESPACE")

  if [ -z "$NAMESPACE_EXISTS" ]; then
    $HELM_CMD install istio-base \
                      kubeslice/istio-base \
                      -n "$NAMESPACE" \
                      --create-namespace

    $HELM_CMD install istiod \
                      kubeslice/istio-discovery \
                      -n "$NAMESPACE" \
                      --create-namespace
  fi
}

# Main function.
function main() {
  checkDependencies
  applyIstio
}

main