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

# Applies the slice operator required by establish the connections between workers.
function applySliceOperator() {
  NAMESPACE=kubeslice-system

  ALREADY_INSTALLED=$($HELM_CMD list -n "$NAMESPACE" | grep kubeslice-worker- | grep deployed)

  # Check if the slice operator is already installed.
  if [ -z "$ALREADY_INSTALLED" ]; then
    FAILED=$($HELM_CMD list -n "$NAMESPACE" | grep kubeslice-worker- | grep failed)

    # Check if the installation was completed.
    if [ -n "$FAILED" ]; then
      $HELM_CMD uninstall kubeslice-worker \
                          -n "$NAMESPACE"
    fi

    echo "Installing the slice operator..."

    $HELM_CMD install kubeslice-worker \
                      kubeslice/kubeslice-worker \
                      -f "$MANIFEST_FILENAME" \
                      -n "$NAMESPACE" \
                      --create-namespace

    if [ $? -eq 0 ]; then
      echo "Slice operator was installed!"
    else
      echo "Slice operator wasn't installed!"

      exit 1
    fi
  else
    echo "Slice operator is already installed!"
  fi
}

# Main function.
function main() {
  checkDependencies
  applySliceOperator
}

main