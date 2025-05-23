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

  if [ -z "$PROJECT_NAME" ]; then
    echo "The project name is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies the project manifest required by kubeslice.
function apply() {
  NAMESPACE=kubeslice-controller

  echo "Applying project..."

  while true; do
    $KUBECTL_CMD apply -f "$MANIFEST_FILENAME" \
                       -n "$NAMESPACE" 2> /dev/null

    if [ $? -eq 0 ]; then
      echo "Project was applied!"

      NAMESPACE="kubeslice-$PROJECT_NAME"

      # Checks if the installation was completed.
      while true; do
        SECRET=$($KUBECTL_CMD get secret \
                                  -n "$NAMESPACE" 2> /dev/null | grep kubeslice-rbac-rw-admin)

        if [ -n "$SECRET" ]; then
          break
        fi

        echo "Waiting until project gets ready..."

        sleep 1
      done

      echo "Project is ready now!"

      break
    fi

    sleep 1
  done
}

# Main function.
function main() {
  checkDependencies
  apply
}

main