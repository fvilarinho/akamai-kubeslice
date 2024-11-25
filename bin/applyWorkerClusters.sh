#!/bin/bash

# Check the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The kubeconfig filename is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$NAMESPACE" ]; then
    echo "The namespace is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$MANIFEST_FILENAME" ]; then
    echo "The manifest filename is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies the clusters manifest replacing the placeholders with the correspondent environment variable value.
function applyClusters() {
  NAMESPACE="kubeslice-$NAMESPACE"

  $KUBECTL_CMD apply -f "$MANIFEST_FILENAME" \
                     -n "$NAMESPACE"
}

# Main function.
function main() {
  checkDependencies
  applyClusters
}

main