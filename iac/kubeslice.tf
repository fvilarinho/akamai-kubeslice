locals {
  applyControllerScriptFilename        = abspath(pathexpand("../bin/applyController.sh"))
  applyManagerScriptFilename           = abspath(pathexpand("../bin/applyManager.sh"))
  applyProjectScriptFilename           = abspath(pathexpand("../bin/applyProject.sh"))
  applyWorkerClustersScriptFilename    = abspath(pathexpand("../bin/applyWorkerClusters.sh"))
  applyWorkerOperatorScriptFilename    = abspath(pathexpand("../bin/applyWorkerOperator.sh"))
  generateWorkerOperatorScriptFilename = abspath(pathexpand("../bin/generateWorkerOperator.sh"))
}

resource "local_file" "controller" {
  filename = abspath(pathexpand("../etc/controller.yaml"))
  content = <<EOT
global:
  imageRegistry: docker.io/aveshasystems
  kubeTally:
    enabled: false
    postgresUser:
    postgresPassword:
    postgresDB:
    postgresAddr:
kubeslice:
  prometheus:
    enabled: true
  controller:
    endpoint: ${linode_lke_cluster.controller.api_endpoints[0]}
imagePullSecrets:
  username: ${var.settings.license.username}
  password: ${var.settings.license.password}
  email: ${var.settings.general.email}
EOT
  depends_on = [ linode_lke_cluster.controller ]
}

resource "local_file" "manager" {
  filename = abspath(pathexpand("../etc/manager.yaml"))
  content = <<EOT
kubeslice:
  dashboard:
    enabled: true
imagePullSecrets:
  username: ${var.settings.license.username}
  password: ${var.settings.license.password}
  email: ${var.settings.general.email}
EOT
}

resource "local_file" "project" {
  filename = abspath(pathexpand("../etc/project.yaml"))
  content = <<EOT
apiVersion: controller.kubeslice.io/v1alpha1
kind: Project
metadata:
  namespace: kubeslice-controller
  name: ${var.settings.general.namespace}
spec:
  serviceAccount:
    readWrite:
      - admin
EOT
}

resource "local_file" "workerClusters" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }
  filename = abspath(pathexpand("../etc/${each.key}-cluster.yaml"))
  content  = <<EOT
apiVersion: controller.kubeslice.io/v1alpha1
kind: Cluster
metadata:
  namespace: kubeslice-${var.settings.general.namespace}
  name: ${each.key}
spec:
  networkInterface: eth0
  clusterProperty:
    geoLocation:
      cloudProvider: "${each.value.cloud}"
      cloudRegion: "${linode_lke_cluster.workers[each.key].region}"
EOT
}

resource "null_resource" "applyController" {
  triggers = {
    when = filemd5(local.applyControllerScriptFilename)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = local_sensitive_file.controllerKubeconfig.filename
      MANIFEST_FILENAME = local_file.controller.filename
    }

    quiet   = true
    command = local.applyControllerScriptFilename
  }

  depends_on = [
    linode_lke_cluster.controller,
    local_sensitive_file.controllerKubeconfig,
    local_file.controller
  ]
}

resource "null_resource" "applyManager" {
  triggers = {
    when = filemd5(local.applyControllerScriptFilename)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = local_sensitive_file.controllerKubeconfig.filename
      MANIFEST_FILENAME = local_file.manager.filename
    }

    quiet   = true
    command = local.applyManagerScriptFilename
  }

  depends_on = [
    linode_lke_cluster.controller,
    local_sensitive_file.controllerKubeconfig,
    null_resource.applyController,
    local_file.manager
  ]
}

resource "null_resource" "applyProject" {
  triggers = {
    when = filemd5(local.applyProjectScriptFilename)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = local_sensitive_file.controllerKubeconfig.filename
      MANIFEST_FILENAME = local_file.project.filename
    }

    quiet   = true
    command = local.applyProjectScriptFilename
  }

  depends_on = [
    linode_lke_cluster.controller,
    local_sensitive_file.controllerKubeconfig,
    null_resource.applyController,
    local_file.project
  ]
}

resource "null_resource" "applyWorkerClusters" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  triggers = {
    when = filemd5(local.applyWorkerClustersScriptFilename)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = local_sensitive_file.controllerKubeconfig.filename
      MANIFEST_FILENAME = local_file.workerClusters[each.key].filename
      NAMESPACE         = var.settings.general.namespace
    }

    quiet   = true
    command = local.applyWorkerClustersScriptFilename
  }

  depends_on = [
    linode_lke_cluster.controller,
    local_sensitive_file.controllerKubeconfig,
    null_resource.applyProject,
    local_file.workerClusters
  ]
}

resource "null_resource" "generateWorkerOperator" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  triggers = {
    when = filemd5(local.generateWorkerOperatorScriptFilename)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = local_sensitive_file.controllerKubeconfig.filename
      MANIFEST_FILENAME = abspath(pathexpand("../etc/${each.key}-operator.yaml"))
      NAMESPACE         = var.settings.general.namespace
      IDENTIFIER        = each.key
      ENDPOINT          = linode_lke_cluster.workers[each.key].api_endpoints[0]
      LICENSE_USERNAME  = var.settings.license.username
      LICENSE_PASSWORD  = var.settings.license.password
      LICENSE_EMAIL     = var.settings.general.email
    }

    quiet   = true
    command = local.generateWorkerOperatorScriptFilename
  }

  depends_on = [
    linode_lke_cluster.controller,
    linode_lke_cluster.workers,
    local_sensitive_file.controllerKubeconfig,
    local_sensitive_file.workersKubeconfig,
    null_resource.applyController,
    null_resource.applyManager,
    null_resource.applyProject,
    null_resource.applyWorkerClusters
  ]
}

resource "null_resource" "applyWorkerOperator" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  triggers = {
    when = "${filemd5(local.applyWorkerOperatorScriptFilename)}|${filemd5(local.generateWorkerOperatorScriptFilename)}"
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = local_sensitive_file.workersKubeconfig[each.key].filename
      MANIFEST_FILENAME = abspath(pathexpand("../etc/${each.key}-operator.yaml"))
      IDENTIFIER        = each.key
    }

    quiet   = true
    command = local.applyWorkerOperatorScriptFilename
  }

  depends_on = [
    linode_lke_cluster.controller,
    linode_lke_cluster.workers,
    local_sensitive_file.controllerKubeconfig,
    local_sensitive_file.workersKubeconfig,
    null_resource.applyController,
    null_resource.applyManager,
    null_resource.applyProject,
    null_resource.applyWorkerClusters,
    null_resource.generateWorkerOperator,
    null_resource.applyPrometheus,
    null_resource.applyIstio
  ]
}