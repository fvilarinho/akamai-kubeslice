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

  if [ -z "$NODES_COUNT" ]; then
    echo "The nodes count is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies the controller manifest replacing the placeholders with the correspondent environment variable value.
function applyController() {
  while true; do
    READY_NODES=$($KUBECTL_CMD describe nodes | grep KubeletReady | wc -l | xargs)

    if [ "$READY_NODES" -eq "$NODES_COUNT" ]; then
      break
    fi

    echo "Waiting until the controller's cluster gets ready..."

    sleep 1
  done

  echo "Controller's cluster is now ready!"

  NAMESPACE=kubeslice-controller

  ALREADY_INSTALLED=$($HELM_CMD list -n "$NAMESPACE" | grep kubeslice-controller- | grep deployed)

  if [ -z "$ALREADY_INSTALLED" ]; then
    FAILED=$($HELM_CMD list -n "$NAMESPACE" | grep kubeslice-controller- | grep failed)

    if [ -n "$FAILED" ]; then
      $HELM_CMD uninstall kubeslice-controller \
                          -n "$NAMESPACE"
    fi

    echo "Installing controller..."

    $HELM_CMD install kubeslice-controller \
                      kubeslice/kubeslice-controller \
                      -f "$MANIFEST_FILENAME" \
                      -n "$NAMESPACE" \
                      --create-namespace

    if [ $? -eq 0 ]; then
      echo "Controller was installed!"
    else
      echo "Controller wasn't installed!"

      exit 1
    fi
  else
    echo "Controller is already installed!"
  fi

  while true; do
    CRDS_EXISTS=$($KUBECTL_CMD get crds -n "$NAMESPACE" | grep "projects.controller.kubeslice.io")

    if [ -n "$CRDS_EXISTS" ]; then
      CRDS_EXISTS=$($KUBECTL_CMD get crds -n "$NAMESPACE" | grep "clusters.controller.kubeslice.io")

      if [ -n "$CRDS_EXISTS" ]; then
        PODS_RUNNING=$($KUBECTL_CMD get pods -n "$NAMESPACE" | grep kubeslice-controller-manager | grep Running)

        if [ -n "$PODS_RUNNING" ]; then
          SVC_RUNNING=$($KUBECTL_CMD get svc -n "$NAMESPACE" | grep kubeslice-controller-webhook-service)

          if [ -n "$SVC_RUNNING" ]; then
            break
          fi
        fi
      fi
    fi

    echo "Waiting until the controller gets ready..."

    sleep 1
  done

  echo "Controller is now ready!"
}

# Main function.
function main() {
  checkDependencies
  applyController
}

main