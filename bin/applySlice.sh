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

# Applies the slice. Slice is the group of workers.
function applySlice() {
  NAMESPACE="kubeslice-$PROJECT_NAME"

  echo "Applying the slice..."

  $KUBECTL_CMD apply -f "$MANIFEST_FILENAME" \
                     -n "$NAMESPACE"

  if [ $? -eq 0 ]; then
    echo "Slice was applied!"
  else
    echo "Slice wasn't applied!"

    exit 1
  fi
}

# Main function.
function main() {
  checkDependencies
  applySlice
}

main