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

# Applies the backend configmaps.
function applyBackendConfigMaps() {
  $KUBECTL_CMD create configmap phonebook-logging-settings \
                                --from-file=logback.xml=../../etc/demo/backend/logback.xml \
                                -n backend \
                                -o yaml \
                                --dry-run=client | $KUBECTL_CMD apply -f -
}

# Applies the frontend configmaps.
function applyFrontendConfigMaps() {
  $KUBECTL_CMD create configmap nginx-settings-template \
                                --from-file=default.conf.template=../../etc/demo/frontend/conf.d/nginx.conf \
                                -n frontend \
                                -o yaml \
                                --dry-run=client | $KUBECTL_CMD apply -f -

  $KUBECTL_CMD create configmap nginx-tls-certificate \
                                --from-file=fullchain.pem=../../etc/demo/frontend/tls/certs/fullchain.pem \
                                -n frontend \
                                -o yaml \
                                --dry-run=client | $KUBECTL_CMD apply -f -

  $KUBECTL_CMD create configmap nginx-tls-certificate-key \
                                --from-file=privkey.pem=../../etc/demo/frontend/tls/private/privkey.pem \
                                -n frontend \
                                -o yaml \
                                --dry-run=client | $KUBECTL_CMD apply -f -

  $KUBECTL_CMD create configmap nginx-auth \
                                --from-file=.htpasswd=../../etc/demo/frontend/.htpasswd \
                                -n frontend \
                                -o yaml \
                                --dry-run=client | $KUBECTL_CMD apply -f -
}

# Applies all configmaps.
function apply() {
  applyFrontendConfigMaps

  if [ -z "$ONLY_FRONTEND" ]; then
    applyBackendConfigMaps
  fi
}

function main () {
  prepareToExecute
  checkDependencies
  apply
}

main
