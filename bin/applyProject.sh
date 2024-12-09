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

# Applies the project manifest required by kubeslice.
function applyProject() {
  NAMESPACE=kubeslice-controller

  echo "Applying project..."

  $KUBECTL_CMD apply -f "$MANIFEST_FILENAME" \
                     -n "$NAMESPACE"

  if [ $? -eq 0 ]; then
    echo "Project was applied!"
  else
    echo "Project wasn't applied!"

    exit 1
  fi
}

# Main function.
function main() {
  checkDependencies
  applyProject
}

main