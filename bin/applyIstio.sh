#!/bin/bash

# Check the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The kubeconfig filename is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies istio stack stack required by slice operator.
function applyIstio() {
  NAMESPACE=istio-system

  ALREADY_INSTALLED=$($HELM_CMD list -n "$NAMESPACE" | grep istio-base- | grep deployed)

  # Check if the istio base is already installed.
  if [ -z "$ALREADY_INSTALLED" ]; then
    FAILED=$($HELM_CMD list -n "$NAMESPACE" | grep istio-base- | grep failed)

    # Check if the installation was completed.
    if [ -n "$FAILED" ]; then
      $HELM_CMD uninstall istio-base \
                          -n "$NAMESPACE"
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

  ALREADY_INSTALLED=$($HELM_CMD list -n "$NAMESPACE" | grep istio-discovery | grep deployed)

  # Check if the istio discovery is already installed.
  if [ -z "$ALREADY_INSTALLED" ]; then
    FAILED=$($HELM_CMD list -n "$NAMESPACE" | grep istio-discovery | grep failed)

    # Check if the installation was completed.
    if [ -n "$FAILED" ]; then
      $HELM_CMD uninstall istiod \
                          -n "$NAMESPACE"
    fi

    echo "Installing istio discovery..."

    $HELM_CMD install istiod \
                      kubeslice/istio-discovery \
                      -n "$NAMESPACE" \
                      --create-namespace

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
  applyIstio
}

main