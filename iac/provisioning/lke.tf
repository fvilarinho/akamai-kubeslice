# Required local variables.
locals {
  lkeWorkers              = { for worker in var.settings.workers : worker.identifier => worker if worker.cloud == "Akamai" }
  applyTagsScriptFilename = abspath(pathexpand("../bin/applyTags.sh"))
}

# Definition of the controller infrastructure.
resource "linode_lke_cluster" "controller" {
  k8s_version = "1.31"
  label       = var.settings.controller.identifier
  tags        = var.settings.controller.tags
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
  tags        = each.value.tags
  region      = each.value.region

  pool {
    # Required for kubeslice.
    labels = {
      "kubeslice.io/node-type" = "gateway"
    }

    type  = each.value.nodes.type
    count = each.value.nodes.count
  }
}

# Fetches the nodes of the clusters.
data "linode_instances" "controllerNodes" {
  filter {
    name   = "id"
    values = [ for node in linode_lke_cluster.controller.pool[0].nodes : node.instance_id ]
  }

  depends_on = [ linode_lke_cluster.controller ]
}

data "linode_instances" "workerNodes" {
  for_each = { for worker in local.lkeWorkers : worker.identifier => worker }

  filter {
    name   = "id"
    values = [ for node in linode_lke_cluster.worker[each.key].pool[0].nodes : node.instance_id ]
  }

  depends_on = [ linode_lke_cluster.worker ]
}

resource "null_resource" "applyControllerTags" {
  # Execute when detected changes.
  triggers = {
    hash         = filemd5(local.applyTagsScriptFilename)
    clusterNodes = join(" ", [ for node in data.linode_instances.controllerNodes.instances : node.id ])
    tags         = join(" ", var.settings.controller.tags)
  }

  provisioner "local-exec" {
    # Required environment variables.
    environment = {
      KUBECONFIG    = local_sensitive_file.controllerKubeconfig.filename
      CLUSTER_NODES = join(" ", [ for node in data.linode_instances.controllerNodes.instances : node.id ])
      TAGS          = join(" ", var.settings.controller.tags)
    }

    quiet   = true
    command = local.applyTagsScriptFilename
  }

  depends_on = [
    linode_lke_cluster.controller,
    data.linode_instances.controllerNodes,
    local_sensitive_file.controllerKubeconfig
  ]
}

resource "null_resource" "applyWorkerTags" {
  for_each = { for worker in local.lkeWorkers : worker.identifier => worker }

  # Execute when detected changes.
  triggers = {
    hash         = filemd5(local.applyTagsScriptFilename)
    clusterNodes = join(" ", [ for node in data.linode_instances.workerNodes[each.key].instances : node.id ])
    tags         = join(" ", each.value.tags)
  }

  provisioner "local-exec" {
    # Required environment variables.
    environment = {
      KUBECONFIG    = local_sensitive_file.workerKubeconfig[each.key].filename
      CLUSTER_NODES = join(" ", [ for node in data.linode_instances.workerNodes[each.key].instances : node.id ])
      TAGS          = join(" ", each.value.tags)
    }

    quiet   = true
    command = local.applyTagsScriptFilename
  }

  depends_on = [
    linode_lke_cluster.worker,
    data.linode_instances.workerNodes,
    local_sensitive_file.workerKubeconfig
  ]
}