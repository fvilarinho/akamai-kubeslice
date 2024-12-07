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

# Applies the project manifest replacing the placeholders with the correspondent environment variable value.
function applyProject() {
  NAMESPACE="kubeslice-$PROJECT_NAME"

  $KUBECTL_CMD apply -f "$MANIFEST_FILENAME" \
                     -n "$NAMESPACE"
}

# Main function.
function main() {
  checkDependencies
  applyProject
}

main