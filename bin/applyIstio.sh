#!/bin/bash

# Checks the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The kubeconfig filename is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies istio stack stack required by slice operator.
function apply() {
  NAMESPACE=istio-system

  ALREADY_INSTALLED=$($HELM_CMD status istio-base \
                                       -n "$NAMESPACE" 2> /dev/null | grep deployed)

  # Checks if the istio base is already installed.
  if [ -z "$ALREADY_INSTALLED" ]; then
    PENDING=$($HELM_CMD status istio-base \
                               -n "$NAMESPACE" 2> /dev/null | grep pending)

    # Checks if the installation was completed.
    if [ -n "$PENDING" ]; then
      $HELM_CMD uninstall istio-base \
                          -n "$NAMESPACE"
    else
      FAILED=$($HELM_CMD list -n "$NAMESPACE" | grep istio-base- | grep failed)

      if [ -n "$FAILED" ]; then
        $HELM_CMD uninstall istio-base \
                            -n "$NAMESPACE"
      fi
    fi

    echo "Installing istio base..."

    $HELM_CMD install istio-base \
                      kubeslice/istio-base \
                      -n "$NAMESPACE" \
                      --create-namespace

    if [ $? -eq 0 ]; then
      echo "Istio base was installed!"
    else
      echo "Istio base wasn't installed!"

      exit 1
    fi
  else
    echo "Istio base is already installed!"
  fi

  ALREADY_INSTALLED=$($HELM_CMD status istiod \
                                       -n "$NAMESPACE" 2> /dev/null | grep deployed)

  # Checks if the istio discovery is already installed.
  if [ -z "$ALREADY_INSTALLED" ]; then
    PENDING=$($HELM_CMD status istiod \
                               -n "$NAMESPACE" 2> /dev/null | grep pending)

    # Checks if the installation was completed.
    if [ -n "$PENDING" ]; then
      $HELM_CMD uninstall istiod \
                          -n "$NAMESPACE"
    else
      FAILED=$($HELM_CMD list -n "$NAMESPACE" | grep istio-discovery- | grep failed)

      if [ -n "$FAILED" ]; then
        $HELM_CMD uninstall istio-discovery \
                            -n "$NAMESPACE"
      fi
    fi

    echo "Installing istio discovery..."

    $HELM_CMD install istiod \
                      kubeslice/istio-discovery \
                      -n "$NAMESPACE"

    if [ $? -eq 0 ]; then
      echo "Istio discovery was installed!"
    else
      echo "Istio discovery wasn't installed!"

      exit 1
    fi
  else
    echo "Istio discovery is already installed!"
  fi
}

# Main function.
function main() {
  checkDependencies
  apply
}

main