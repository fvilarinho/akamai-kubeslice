#!/bin/bash

# Checks the dependencies of this script.
function checkDependencies() {
  if [ -z "$RESOURCE_GROUP_NAME" ]; then
    echo "The worker resource group name is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$CONTROLLER_IDENTIFIER" ]; then
    echo "The controller identifier is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies the required rules.
function apply() {
  CONTROLLER_INSTANCES=$($LINODE_CLI_CMD lke pools-list $($LINODE_CLI_CMD lke clusters-list | grep $CONTROLLER_IDENTIFIER | awk -F' ' '{print $2}') --json | $JQ_CMD -r '.[].nodes.instance_id')
  PRIORITY=100

  for CONTROLLER_INSTANCE in $CONTROLLER_INSTANCES
  do
    IP="$($LINODE_CLI_CMD linodes ips-list $CONTROLLER_INSTANCE --json | $JQ_CMD -r '.[0].ipv4.public[0].address')"

    $AZ_CLI_CMD network nsg rule create \
                --resource-group $RESOURCE_GROUP_NAME \
                --nsg-name $($AZ_CLI_CMD network nsg list --resource-group $RESOURCE_GROUP_NAME --query '[0].name' -o tsv) \
                --name "allow-controller-instance-$CONTROLLER_INSTANCE" \
                --priority $PRIORITY \
                --protocol "Tcp" \
                --destination-port-ranges "0-65535" \
                --access "Allow" \
                --source-address-prefixes "$IP" \
                --destination-address-prefixes "*" \
                --direction "Inbound" > /dev/null

    ((PRIORITY++))
  done
}

# Main function.
function main() {
  checkDependencies "$1"
  apply
}

main "$1"