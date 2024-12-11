terraform {
  # Saves the state in a remote backend (S3 Bucket).
  backend "s3" {
    bucket                      = "fvilarin-devops"
    key                         = "akamai-kubeslice.tfstate"
    region                      = "us-east-1"
    endpoint                    = "us-east-1.linodeobjects.com"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
  }

  # Definition of required providers.
  required_providers {
    linode = {
      source = "linode/linode"
    }

    aws = {
      source = "hashicorp/aws"
    }

    null = {
      source = "hashicorp/null"
    }

    random = {
      source = "hashicorp/random"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.108.0"
    }
  }
}

# Definition of Akamai Cloud Computing provider.
provider "linode" {
  token = var.settings.providers.akamai.token
}

# Definition of Microsoft Azure provider.
provider "azurerm" {
  features {}

  subscription_id = var.settings.providers.azure.subscriptionId
  tenant_id       = var.settings.providers.azure.tenantId
  client_id       = var.settings.providers.azure.clientId
  client_secret   = var.settings.providers.azure.clientSecret
  skip_provider_registration = true
}

# Saves the worker kubeconfig locally.
resource "local_sensitive_file" "workerKubeconfig" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  filename        = abspath(pathexpand("../etc/${each.key}.kubeconfig"))
  content_base64  = (each.value.cloud == "Akamai" ? linode_lke_cluster.worker[each.key].kubeconfig : base64encode(azurerm_kubernetes_cluster.worker[each.key].kube_config_raw))
  file_permission = "600"
  depends_on      = [
    linode_lke_cluster.worker,
    azurerm_kubernetes_cluster.worker
  ]
}