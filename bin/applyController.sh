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

# Applies the controller manifest replacing the placeholders with the correspondent environment variable value.
function applyController() {
  NAMESPACE=kubeslice-controller

  NAMESPACE_EXISTS=$($KUBECTL_CMD get ns | grep "$NAMESPACE")

  if [ -z "$NAMESPACE_EXISTS" ]; then
    $HELM_CMD install kubeslice-controller \
                      kubeslice/kubeslice-controller \
                      -f "$MANIFEST_FILENAME" \
                      -n "$NAMESPACE" \
                      --create-namespace
  fi

  while true; do
    echo "Waiting for controller gets ready..."

    PODS_RUNNING=$($KUBECTL_CMD get pods -n "$NAMESPACE" | grep kubeslice-controller-manager | grep Running)

    if [ -n "$PODS_RUNNING" ]; then
      sleep 5

      SVC_RUNNING=$($KUBECTL_CMD get svc -n "$NAMESPACE" | grep kubeslice-controller-webhook-service)

      if [ -n "$SVC_RUNNING" ]; then
        sleep 5

        CRDS_EXISTS=$($KUBECTL_CMD get crds -n "$NAMESPACE" | grep "projects.controller.kubeslice.io")

        if [ -n "$CRDS_EXISTS" ]; then
          sleep 5

          CRDS_EXISTS=$($KUBECTL_CMD get crds -n "$NAMESPACE" | grep "clusters.controller.kubeslice.io")

          if [ -n "$CRDS_EXISTS" ]; then
            sleep 5

            break
          fi
        fi
      fi
    fi

    sleep 5
  done

  echo "Controller is running!"
}

# Main function.
function main() {
  checkDependencies
  applyController
}

main