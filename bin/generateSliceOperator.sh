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

  if [ -z "$WORKER_CLUSTER_IDENTIFIER" ]; then
    echo "The worker cluster identifier is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$WORKER_CLUSTER_ENDPOINT" ]; then
    echo "The worker cluster endpoint is not defined! Please define it first to continue!"

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

# Creates the slice operator installation manifest.
function generateSliceOperator() {
  NAMESPACE="kubeslice-$PROJECT_NAME"
  SECRET_NAME="kubeslice-rbac-worker-$WORKER_CLUSTER_IDENTIFIER"

  PROJECT_NAMESPACE=$($KUBECTL_CMD get secrets "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.namespace}')
  CONTROLLER_ENDPOINT=$($KUBECTL_CMD get secrets "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.controllerEndpoint}')
  CA_CRT=$($KUBECTL_CMD get secrets "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.ca\.crt}')
  TOKEN=$($KUBECTL_CMD get secrets "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.token}')

  echo "controllerSecret:
  namespace: $PROJECT_NAMESPACE
  endpoint: $CONTROLLER_ENDPOINT
  ca.crt: $CA_CRT
  token: $TOKEN

cluster:
  name: $WORKER_CLUSTER_IDENTIFIER
  endpoint: $WORKER_CLUSTER_ENDPOINT

kubesliceNetworking:
  enabled: true

imagePullSecrets:
  repository: https://index.docker.io/v1/
  username: $LICENSE_USERNAME
  password: $LICENSE_PASSWORD
  email: $LICENSE_EMAIL" > "$MANIFEST_FILENAME"
}

# Main function.
function main() {
  checkDependencies
  generateSliceOperator
}

main