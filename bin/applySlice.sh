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

  if [ -z "$PROJECT_NAME" ]; then
    echo "The project name is not defined! Please define it first to continue!"

    exit 1
  fi
}

function applySlice() {
  NAMESPACE="kubeslice-$PROJECT_NAME"

  echo "Applying slice..."

  $KUBECTL_CMD apply -f "$MANIFEST_FILENAME" \
                     -n "$NAMESPACE"

  echo "Slice was applied!"
}

# Main function.
function main() {
  checkDependencies
  applySlice
}

main