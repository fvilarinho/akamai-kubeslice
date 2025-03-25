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

# Applies the manager (UI) manifest.
function apply() {
  NAMESPACE=kubeslice-controller

  ALREADY_INSTALLED=$($HELM_CMD status kubeslice-ui \
                                       -n "$NAMESPACE" 2> /dev/null | grep deployed)

  # Checks if the manager (UI) is already installed.
  if [ -z "$ALREADY_INSTALLED" ]; then
    PENDING=$($HELM_CMD status kubeslice-ui \
                               -n "$NAMESPACE" 2> /dev/null | grep pending)

    # Checks if the installation was completed.
    if [ -n "$PENDING" ]; then
      $HELM_CMD uninstall kubeslice-ui \
                          -n "$NAMESPACE"
    else
      FAILED=$($HELM_CMD list -n "$NAMESPACE" | grep kubeslice-ui- | grep failed)

      if [ -n "$FAILED" ]; then
        $HELM_CMD uninstall kubeslice-ui \
                            -n "$NAMESPACE"
      fi
    fi

    echo "Installing manager..."

    $HELM_CMD install kubeslice-ui \
                      kubeslice/kubeslice-ui \
                      -f "$MANIFEST_FILENAME" \
                      -n "$NAMESPACE"

    if [ $? -eq 0 ]; then
      echo "Manager was installed!"

      while true; do
        SERVICE=$($KUBECTL_CMD get svc \
                                   -n "$NAMESPACE" 2> /dev/null | grep kubeslice-ui-proxy)

        if [ -n "$SERVICE" ]; then
          break
        fi

        echo "Waiting until manager gets ready..."

        sleep 1
      done

      echo "Manager is now ready!"
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
  apply
}

main