module "provisioning" {
  source = "./provisioning"

  credentials = var.credentials
  settings    = var.settings
}