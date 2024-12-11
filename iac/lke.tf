# Required local variables.
locals {
  lkeWorkers = { for worker in var.settings.workers : worker.identifier => worker if worker.cloud == "Akamai" }
  lkeNodes   = concat([ for node in linode_lke_cluster.controller.pool[0].nodes : node.instance_id ],
                      flatten([ for worker in local.lkeWorkers : [ for node in linode_lke_cluster.worker[worker.identifier].pool[0].nodes : node.instance_id ]]))
}

# Definition of the controller infrastructure.
resource "linode_lke_cluster" "controller" {
  k8s_version = "1.31"
  label       = var.settings.controller.identifier
  tags        = var.settings.general.tags
  region      = var.settings.controller.region

  pool {
    type  = var.settings.controller.nodes.type
    count = var.settings.controller.nodes.count
  }
}

# Saves the controller kubeconfig locally.
resource "local_sensitive_file" "controllerKubeconfig" {
  filename        = abspath(pathexpand("../etc/${var.settings.controller.identifier}.kubeconfig"))
  content_base64  = linode_lke_cluster.controller.kubeconfig
  file_permission = "600"
  depends_on      = [ linode_lke_cluster.controller ]
}

# Definition of the worker infrastructure.
resource "linode_lke_cluster" "worker" {
  for_each = { for worker in local.lkeWorkers : worker.identifier => worker }

  k8s_version = "1.31"
  label       = each.key
  tags        = var.settings.general.tags
  region      = each.value.region

  pool {
    # Required for kubeslice.
    labels = {
      "kubeslice.io/node-type" = "gateway"
    }

    type  = each.value.nodes.type
    count = each.value.nodes.count
  }

  depends_on = [ null_resource.applyProject ]
}

# Fetches all IPs (private and public) of the clusters' nodes to be allowed in the firewall.
data "linode_instances" "lkeNodes" {
  filter {
    name   = "id"
    values = local.lkeNodes
  }

  depends_on = [
    linode_lke_cluster.controller,
    linode_lke_cluster.worker
  ]
}