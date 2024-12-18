# Required local variables.
locals {
  eksWorkers = { for worker in var.settings.workers : worker.identifier => worker if worker.cloud == "AWS" }
}

# Fetches the workers' clusters metadata.
data "aws_eks_cluster" "worker" {
  for_each = { for worker in local.eksWorkers : worker.identifier => worker }

  name = each.key
}

data "aws_eks_cluster_auth" "worker" {
  for_each = { for worker in local.eksWorkers : worker.identifier => worker }

  name = each.key
}

# Fetches the workers' clusters node group.
data "aws_eks_node_group" "worker" {
  for_each = { for worker in local.eksWorkers : worker.identifier => worker }

  cluster_name    = each.key
  node_group_name = "default"
}

# Fetches all nodes of the workers' clusters.
data "aws_instances" "eksNodes" {
  for_each = { for worker in local.eksWorkers : worker.identifier => worker }

  filter {
    name   = "tag:eks:nodegroup-name"
    values = [ data.aws_eks_node_group.worker[each.key].node_group_name ]
  }

  filter {
    name   = "instance-state-name"
    values = [ "running" ]
  }
}