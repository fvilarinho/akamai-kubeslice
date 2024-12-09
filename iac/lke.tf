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

resource "local_sensitive_file" "controllerKubeconfig" {
  filename        = abspath(pathexpand("../etc/${var.settings.controller.identifier}.kubeconfig"))
  content_base64  = linode_lke_cluster.controller.kubeconfig
  file_permission = "600"
  depends_on      = [ linode_lke_cluster.controller ]
}

resource "linode_lke_cluster" "worker" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  k8s_version = "1.31"
  label       = each.key
  tags        = var.settings.general.tags
  region      = each.value.region

  pool {
    labels = {
      "kubeslice.io/node-type" = "gateway"
    }

    type  = each.value.nodes.type
    count = each.value.nodes.count
  }

  depends_on = [ null_resource.applyProject ]
}

resource "local_sensitive_file" "workerKubeconfig" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  filename        = abspath(pathexpand("../etc/${each.key}.kubeconfig"))
  content_base64  = linode_lke_cluster.worker[each.key].kubeconfig
  file_permission = "600"
  depends_on      = [ linode_lke_cluster.worker ]
}
