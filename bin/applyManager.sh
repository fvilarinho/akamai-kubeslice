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

# Applies the manager (UI) manifest.
function applyManager() {
  NAMESPACE=kubeslice-controller

  ALREADY_INSTALLED=$($HELM_CMD list -n "$NAMESPACE" | grep kubeslice-ui- | grep deployed)

  # Check if the manager (UI) is already installed.
  if [ -z "$ALREADY_INSTALLED" ]; then
    FAILED=$($HELM_CMD list -n "$NAMESPACE" | grep kubeslice-ui- | grep failed)

    # Check if the installation was completed.
    if [ -n "$FAILED" ]; then
      $HELM_CMD uninstall kubeslice-ui \
                          -n "$NAMESPACE"
    fi

    echo "Installing manager..."

    $HELM_CMD install kubeslice-ui \
                      kubeslice/kubeslice-ui \
                      -f "$MANIFEST_FILENAME" \
                      -n "$NAMESPACE"

    if [ $? -eq 0 ]; then
      echo "Manager was installed!"
    else
      echo "Manager wasn't installed!"

      exit 1
    fi
  else
    echo "Manager is already installed!"
  fi
}

# Main function.
function main() {
  checkDependencies
  applyManager
}

main