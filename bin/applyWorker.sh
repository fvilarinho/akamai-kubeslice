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

# Applies the worker manifest replacing the placeholders with the correspondent environment variable value.
function applyWorker() {
  NAMESPACE="kubeslice-$PROJECT_NAME"

  echo "Applying worker..."

  $KUBECTL_CMD apply -f "$MANIFEST_FILENAME" \
                     -n "$NAMESPACE"

  if [ $? -eq 0 ]; then
    echo "Worker was applied!"
  else
    echo "Worker wasn't applied!"

    exit 1
  fi
}

# Main function.
function main() {
  checkDependencies
  applyWorker
}

main