resource "linode_lke_cluster" "controller" {
  k8s_version = "1.31"
  label       = var.settings.controller.identifier
  tags        = concat(var.settings.general.tags, [ var.settings.general.namespace ])
  region      = var.settings.controller.nodes.region

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

resource "linode_lke_cluster" "workers" {
  for_each    = { for worker in var.settings.workers : worker.identifier => worker }
  k8s_version = "1.31"
  label       = each.key
  tags        = concat(var.settings.general.tags, [ var.settings.general.namespace ])
  region      = each.value.nodes.region

  pool {
    labels = {
      "kubeslice.io/node-type" = "gateway"
    }

    type  = each.value.nodes.type
    count = each.value.nodes.count
  }
}

resource "local_sensitive_file" "workersKubeconfig" {
  for_each        = { for worker in var.settings.workers : worker.identifier => worker }
  filename        = abspath(pathexpand("../etc/${each.key}.kubeconfig"))
  content_base64  = linode_lke_cluster.workers[each.key].kubeconfig
  file_permission = "600"
  depends_on      = [ linode_lke_cluster.workers ]
}
