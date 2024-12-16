# Required local variables.
locals {
  eksWorkers = { for worker in var.settings.workers : worker.identifier => worker if worker.cloud == "AWS" }
}

# Fetches the EKS cluster already provisioned.
data "aws_eks_cluster" "worker" {
  for_each = { for worker in local.eksWorkers : worker.identifier => worker }

  name = each.key
}

# Fetches the EKS cluster authentication metadata.
data "aws_eks_cluster_auth" "worker" {
  for_each = { for worker in local.eksWorkers : worker.identifier => worker }

  name = each.key
}

# Fetches the EKS cluster nodes.
data "aws_instances" "eksNodes" {
  filter {
    name   = "tag:aws:eks:nodegroup-name"
    values = [ "default" ]
  }
}