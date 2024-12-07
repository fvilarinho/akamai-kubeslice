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

function applySliceOperator() {
  NAMESPACE=kubeslice-system

  ALREADY_INSTALLED=$($HELM_CMD list -n "$NAMESPACE" | grep kubeslice-worker- | grep deployed)

  if [ -z "$ALREADY_INSTALLED" ]; then
    echo "Applying slice operator..."

    $HELM_CMD install kubeslice-worker \
                      kubeslice/kubeslice-worker \
                      -f "$MANIFEST_FILENAME" \
                      -n "$NAMESPACE" \
                      --create-namespace
  fi

  echo "Slice operator is now ready!"
}

# Main function.
function main() {
  checkDependencies
  applySliceOperator
}

main