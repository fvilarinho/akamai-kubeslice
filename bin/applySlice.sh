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

  while true; do
    $KUBECTL_CMD apply -f "$MANIFEST_FILENAME" \
                       -n "$NAMESPACE" 2> /dev/null

    if [ $? -eq 0 ]; then
      echo "Slice was applied!"

      break
    fi

    echo "Waiting until slice gets ready..."

    sleep 1
  done
}

# Main function.
function main() {
  checkDependencies
  applySlice
}

main