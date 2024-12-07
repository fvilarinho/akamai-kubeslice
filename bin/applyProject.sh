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

  if [ -z "$PROJECT_NAME" ]; then
    echo "The project name is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies the project manifest replacing the placeholders with the correspondent environment variable value.
function applyProject() {
  NAMESPACE=kubeslice-controller

  echo "Applying project..."

  $KUBECTL_CMD apply -f "$MANIFEST_FILENAME" \
                     -n "$NAMESPACE"

  README_FILENAME=../README.txt

  echo "Welcome to Avesha Kubeslice Enterprise" > $README_FILENAME
  echo "======================================" >> $README_FILENAME
  echo >> $README_FILENAME
  echo "Use the token below to authenticate in the https://$($KUBECTL_CMD get svc kubeslice-ui-proxy -n kubeslice-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):" >> $README_FILENAME

  $KUBECTL_CMD get secret kubeslice-rbac-rw-admin -n kubeslice-$PROJECT_NAME -o jsonpath='{.data.token}' | base64 --decode >> $README_FILENAME

  cat $README_FILENAME
}

# Main function.
function main() {
  checkDependencies
  applyProject
}

main