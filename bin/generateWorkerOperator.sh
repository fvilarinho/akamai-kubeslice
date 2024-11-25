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

  if [ -z "$NAMESPACE" ]; then
    echo "The namespace is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$IDENTIFIER" ]; then
    echo "The identifier is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$ENDPOINT" ]; then
    echo "The endpoint is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$LICENSE_USERNAME" ]; then
    echo "The license username is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$LICENSE_PASSWORD" ]; then
    echo "The license password is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$LICENSE_EMAIL" ]; then
    echo "The license email is not defined! Please define it first to continue!"

    exit 1
  fi
}

function generateOperator() {
  PROJECT_NAMESPACE=$($KUBECTL_CMD get secrets "kubeslice-rbac-worker-$IDENTIFIER" -n "kubeslice-$NAMESPACE" -o jsonpath='{.data.namespace}')
  CONTROLLER_ENDPOINT=$($KUBECTL_CMD get secrets "kubeslice-rbac-worker-$IDENTIFIER" -n "kubeslice-$NAMESPACE" -o jsonpath='{.data.controllerEndpoint}')
  CA_CRT=$($KUBECTL_CMD get secrets "kubeslice-rbac-worker-$IDENTIFIER" -n "kubeslice-$NAMESPACE" -o jsonpath='{.data.ca\.crt}')
  TOKEN=$($KUBECTL_CMD get secrets "kubeslice-rbac-worker-$IDENTIFIER" -n "kubeslice-$NAMESPACE" -o jsonpath='{.data.token}')

  echo "controllerSecret:" > "$MANIFEST_FILENAME"
  echo "  namespace: $PROJECT_NAMESPACE" >> "$MANIFEST_FILENAME"
  echo "  endpoint: $CONTROLLER_ENDPOINT" >> "$MANIFEST_FILENAME"
  echo "  ca.crt: $CA_CRT" >> "$MANIFEST_FILENAME"
  echo "  token: $TOKEN" >> "$MANIFEST_FILENAME"
  echo "cluster:" >> "$MANIFEST_FILENAME"
  echo "  name: $IDENTIFIER" >> "$MANIFEST_FILENAME"
  echo "  endpoint: $ENDPOINT" >> "$MANIFEST_FILENAME"
  echo "kubesliceNetworking:" >> "$MANIFEST_FILENAME"
  echo "  enabled: true" >> "$MANIFEST_FILENAME"
  echo "imagePullSecrets:" >> "$MANIFEST_FILENAME"
  echo "  username: $LICENSE_USERNAME" >> "$MANIFEST_FILENAME"
  echo "  password: $LICENSE_PASSWORD" >> "$MANIFEST_FILENAME"
  echo "  email: $LICENSE_EMAIL" >> "$MANIFEST_FILENAME"
}

# Main function.
function main() {
  checkDependencies
  generateOperator
}

main