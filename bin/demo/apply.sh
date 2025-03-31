#!/bin/bash

# Checks the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "kubeconfig is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$KUBECTL_CMD" ]; then
    echo "kubectl is not installed! Please install it first to continue!"

    exit 1
  fi

  if [ -z "$CERTBOT_CMD" ]; then
    echo "certbot is not installed! Please install it first to continue!"

    exit 1
  fi

  if [ -z "$HTPASSWD_CMD" ]; then
    echo "htpasswd is not installed! Please install it first to continue!"

    exit 1
  fi
}

# Prepares the environment to execute this script.
function prepareToExecute() {
  cd ../../ || exit 1

  source functions.sh

  cd bin/demo || exit 1
}

# Applies the secrets and configmaps.
function applySettings() {
  ./generateCertificateAndCredentials.sh
  ./applySecrets.sh
  ./applyConfigMaps.sh
}

# Applies the storages.
function applyStorages() {
  if [ -z "$ONLY_FRONTEND" ]; then
    export MANIFEST_FILENAME=../../etc/demo/database/storages.yaml

    ./applyManifest.sh
  fi
}

# Applies the services.
function applyServices() {
  export MANIFEST_FILENAME=../../etc/demo/frontend/services.yaml

  ./applyManifest.sh

  if [ -z "$ONLY_FRONTEND" ]; then
    export MANIFEST_FILENAME=../../etc/demo/backend/services.yaml

    ./applyManifest.sh

    export MANIFEST_FILENAME=../../etc/demo/database/services.yaml

    ./applyManifest.sh
  fi
}

# Applies the deployments.
function applyDeployments() {
  export MANIFEST_FILENAME=../../etc/demo/frontend/deployments.yaml

  ./applyManifest.sh

  if [ -z "$ONLY_FRONTEND" ]; then
    export MANIFEST_FILENAME=../../etc/demo/backend/deployments.yaml

    ./applyManifest.sh

    export MANIFEST_FILENAME=../../etc/demo/database/deployments.yaml

    ./applyManifest.sh
  fi
}

# Applies the stack.
function apply() {
  applySettings
  applyStorages
  applyServices
  applyDeployments
}

# Main function.
function main() {
  prepareToExecute
  checkDependencies
  apply
}

main