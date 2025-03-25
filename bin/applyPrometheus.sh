#!/bin/bash

# Checks the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The kubeconfig filename is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies prometheus stack required by slice operator.
function apply() {
  NAMESPACE=monitoring

  ALREADY_INSTALLED=$($HELM_CMD status prometheus \
                                       -n "$NAMESPACE" 2> /dev/null | grep deployed)

  # Checks if the prometheus is already installed.
  if [ -z "$ALREADY_INSTALLED" ]; then
    PENDING=$($HELM_CMD status prometheus \
                               -n "$NAMESPACE" 2> /dev/null | grep pending)

    # Checks if the installation was completed.
    if [ -n "$PENDING" ]; then
      $HELM_CMD uninstall prometheus \
                          -n "$NAMESPACE"
    else
      FAILED=$($HELM_CMD list -n "$NAMESPACE" | grep prometheus- | grep failed)

      if [ -n "$FAILED" ]; then
        $HELM_CMD uninstall prometheus \
                            -n "$NAMESPACE"
      fi
    fi

    echo "Installing prometheus..."

    $HELM_CMD install prometheus \
                      kubeslice/prometheus \
                      -n "$NAMESPACE" \
                      --create-namespace

    if [ $? -eq 0 ]; then
      echo "Prometheus was installed!"
    else
      echo "Prometheus wasn't installed!"

      exit 1
    fi
  else
    echo "Prometheus is already installed!"
  fi
}

# Main function.
function main() {
  checkDependencies
  apply
}

main