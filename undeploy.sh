#!/bin/bash

# Checks the dependencies to run this scripts.
function checkDependencies() {
  if [ -z "$TERRAFORM_CMD" ]; then
    echo "terraform is not installed! Please install it first to continue!"

    exit 1
  fi
}

# Prepares the environment to execute this script.
function prepareToExecute() {
  source functions.sh

  showBanner

  cd iac || exit 1
}

# Undeploys the provisioned infrastructure.
function undeploy() {
  # Initializes Terraform providers and state.
  $TERRAFORM_CMD init \
                 -upgrade \
                 -migrate-state

  # Destroys the provisioned infrastructure.
  $TERRAFORM_CMD destroy \
                 -auto-approve
}

# Main function.
function main() {
  prepareToExecute
  checkDependencies
  undeploy
}

main