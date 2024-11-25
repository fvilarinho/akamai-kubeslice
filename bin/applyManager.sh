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

# Applies the manager manifest replacing the placeholders with the correspondent environment variable value.
function applyManager() {
  NAMESPACE=kubeslice-controller

  $HELM_CMD install kubeslice-ui \
                    kubeslice/kubeslice-ui \
                    -f "$MANIFEST_FILENAME" \
                    -n "$NAMESPACE"
}

# Main function.
function main() {
  checkDependencies
  applyManager
}

main