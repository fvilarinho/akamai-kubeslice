# Definition of Microsoft Azure provider.
provider "azurerm" {
  features {}

  subscription_id = var.credentials.azure.subscriptionId
  tenant_id       = var.credentials.azure.tenantId
  client_id       = var.credentials.azure.clientId
  client_secret   = var.credentials.azure.clientSecret
}