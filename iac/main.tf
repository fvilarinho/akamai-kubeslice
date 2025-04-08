module "provisioning" {
  source = "./provisioning"

  credentials = var.credentials
  settings    = var.settings
}

module "publishing" {
  source = "./publishing"

  credentials         = var.credentials
  settings            = var.settings
  sliceNodeBalancerIp = module.provisioning.sliceNodeBalancerIp
}