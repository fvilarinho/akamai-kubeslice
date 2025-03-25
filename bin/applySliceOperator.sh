#!/bin/bash

# Checks the dependencies of this script.
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
function apply() {
  NAMESPACE=kubeslice-system

  ALREADY_INSTALLED=$($HELM_CMD status kubeslice-worker \
                                       -n "$NAMESPACE" 2> /dev/null | grep deployed)

  # Checks if the slice operator is already installed.
  if [ -z "$ALREADY_INSTALLED" ]; then
    PENDING=$($HELM_CMD status kubeslice-worker \
                               -n "$NAMESPACE" 2> /dev/null | grep pending)

    # Checks if the installation was completed.
    if [ -n "$PENDING" ]; then
      $HELM_CMD uninstall kubeslice-worker \
                          -n "$NAMESPACE"
    else
      FAILED=$($HELM_CMD list -n "$NAMESPACE" | grep kubeslice-worker- | grep failed)

      if [ -n "$FAILED" ]; then
        $HELM_CMD uninstall kubeslice-worker \
                            -n "$NAMESPACE"
      fi
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
  apply
}

main