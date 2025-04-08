terraform {
  # Definition of required providers.
  required_providers {
    linode = {
      source = "linode/linode"
      version = "2.31.1"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.14.0"
    }

    null = {
      source = "hashicorp/null"
      version = "3.2.3"
    }

    local = {
      source = "hashicorp/local"
      version = "2.5.2"
    }

    external = {
      source = "hashicorp/external"
      version = "2.3.4"
    }
  }
}

# Saves the worker kubeconfig locally.
resource "local_sensitive_file" "workerKubeconfig" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker}

  filename        = abspath(pathexpand("../etc/${each.key}.kubeconfig"))
  content_base64  = (each.value.cloud == "Akamai" ? linode_lke_cluster.worker[each.key].kubeconfig : base64encode(azurerm_kubernetes_cluster.worker[each.key].kube_config_raw))
  file_permission = "600"

  depends_on = [
    linode_lke_cluster.worker,
    azurerm_kubernetes_cluster.worker
  ]
}