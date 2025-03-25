#!/bin/bash

# Checks the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "kubeconfig is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Prepares the environment to execute this script.
function prepareToExecute() {
  source ../../functions.sh
}

# Applies the database secrets.
function applyDatabaseSecrets() {
  $KUBECTL_CMD create secret generic mariadb \
                                     --from-literal=DB_USER=$DB_USER \
                                     --from-literal=DB_PASS=$DB_PASS \
                                     --from-literal=DB_NAME=$DB_NAME \
                                     --from-literal=DB_ROOT_PASS=$DB_ROOT_PASS \
                                     -n database \
                                     -o yaml \
                                     --dry-run=client | $KUBECTL_CMD apply -f -
}

# Applies the backend secrets.
function applyBackendSecrets() {
  $KUBECTL_CMD create secret generic phonebook \
                                     --from-literal=DB_HOST=$DB_HOST.database.svc.cluster.local \
                                     --from-literal=DB_USER=$DB_USER \
                                     --from-literal=DB_PASS=$DB_PASS \
                                     --from-literal=DB_NAME=$DB_NAME \
                                     -n backend \
                                     -o yaml \
                                     --dry-run=client | $KUBECTL_CMD apply -f -
}

# Applies the frontend secrets.
function applyFrontendSecrets() {
  $KUBECTL_CMD create secret generic nginx \
                                     --from-literal=BACKEND_HOST=$BACKEND_HOST.backend.svc.cluster.local \
                                     -n frontend \
                                     -o yaml \
                                     --dry-run=client | $KUBECTL_CMD apply -f -
}

# Applies all secrets.
function apply() {
  applyFrontendSecrets

  if [ -z "$ONLY_FRONTEND" ]; then
    applyBackendSecrets
    applyDatabaseSecrets
  fi
}

# Main function.
function main () {
  prepareToExecute
  checkDependencies
  apply
}

main
