# Check the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The kubeconfig filename is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$PROJECT_NAME" ]; then
    echo "The project name is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Creates a README file.
function generateReadme() {
  README_FILENAME=../README.txt

  NAMESPACE=kubeslice-controller

  echo "WELCOME TO AKAMAI KUBESLICE" > "$README_FILENAME"
  echo "===========================" >> "$README_FILENAME"
  echo >> "$README_FILENAME"

  URL=$($KUBECTL_CMD get svc kubeslice-ui-proxy \
                             -n "$NAMESPACE" \
                             -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

  echo "To access the URL, please open the URL https://$URL in your preferred browser and use the token below to authenticate:" >> "$README_FILENAME"

  NAMESPACE=kubeslice-$PROJECT_NAME

  TOKEN=$($KUBECTL_CMD get secret kubeslice-rbac-rw-admin \
                                  -n "$NAMESPACE" \
                                  -o jsonpath='{.data.token}' | base64 --decode)

  echo "$TOKEN" >> "$README_FILENAME"

  cat "$README_FILENAME"
}

# Main function.
function main() {
  checkDependencies
  generateReadme
}

main