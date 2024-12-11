# Required local variables.
locals {
  azureWorkers = { for worker in var.settings.workers : worker.identifier => worker if worker.cloud == "Azure" }
  aksNodes     = flatten([
    for worker in local.azureWorkers :
    [
      for resource in data.azurerm_resources.worker[worker.identifier].resources :
      {
        identifier    = resource.name,
        resourceGroup = data.azurerm_resources.worker[worker.identifier].resource_group_name
      }

      if resource.type == "Microsoft.Network/publicIPAddresses"
    ]
  ])
}

# Provisioning of the resource groups for worker.
resource "azurerm_resource_group" "worker" {
  for_each = { for worker in local.azureWorkers : worker.identifier => worker }

  name     = each.key
  location = each.value.region

  depends_on = [
    linode_lke_cluster.worker,
    null_resource.applyProject
  ]
}

# Provisioning of the workers' clusters.
resource "azurerm_kubernetes_cluster" "worker" {
  for_each = { for worker in local.azureWorkers : worker.identifier => worker }

  name                = each.key
  dns_prefix          = each.key
  resource_group_name = azurerm_resource_group.worker[each.key].name
  location            = azurerm_resource_group.worker[each.key].location

  default_node_pool {
    name                        = "default"
    temporary_name_for_rotation = "defaulttmp"
    node_count                  = each.value.nodes.count
    vm_size                     = each.value.nodes.type
    enable_node_public_ip       = true

    # Required for kubeslice.
    node_labels = {
      "kubeslice.io/node-type" = "gateway"
    }

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_policy = "calico"
    network_plugin = "azure"
  }

  depends_on = [
    azurerm_resource_group.worker,
    null_resource.applyProject
  ]
}

# Fetches all resources provisioned for the workers' clusters.
data "azurerm_resources" "worker" {
  for_each = { for worker in local.azureWorkers : worker.identifier => worker }

  resource_group_name = azurerm_kubernetes_cluster.worker[each.key].node_resource_group

  depends_on = [ azurerm_kubernetes_cluster.worker ]
}

# Fetches all nodes of the workers' clusters.
data "azurerm_public_ip" "aksNodes" {
  for_each = { for node in local.aksNodes : node.identifier => node }

  name                = each.key
  resource_group_name = each.value.resourceGroup

  depends_on = [ data.azurerm_resources.worker ]
}