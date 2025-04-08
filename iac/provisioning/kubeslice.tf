# Required local variables.
locals {
  applyControllerScriptFilename          = abspath(pathexpand("../bin/applyController.sh"))
  applyManagerScriptFilename             = abspath(pathexpand("../bin/applyManager.sh"))
  applyProjectScriptFilename             = abspath(pathexpand("../bin/applyProject.sh"))
  applyWorkerScriptFilename              = abspath(pathexpand("../bin/applyWorker.sh"))
  fetchSliceNodeIpScriptFilename         = abspath(pathexpand("../bin/fetchSliceNodeIp.sh"))
  fetchSliceNodeBalancerIpScriptFilename = abspath(pathexpand("../bin/fetchSliceNodeBalancerIp.sh"))
  generateSliceOperatorScriptFilename    = abspath(pathexpand("../bin/generateSliceOperator.sh"))
  applySliceOperatorScriptFilename       = abspath(pathexpand("../bin/applySliceOperator.sh"))
  applySliceScriptFilename               = abspath(pathexpand("../bin/applySlice.sh"))
  generateReadmeScriptFilename           = abspath(pathexpand("../bin/generateReadme.sh"))

  sliceWorkers = [ for worker in var.settings.workers : <<EOT
    - ${worker.identifier}
EOT
  ]

  sliceNamespaces = [ for namespace in var.settings.slice.namespaces : <<EOT
      - namespace: ${namespace}
        clusters:
          - "*"
EOT
  ]
}

# Controller installation manifest.
resource "local_file" "controller" {
  filename = abspath(pathexpand("../etc/controller.yaml"))
  content  = <<EOT
global:
  imageRegistry: docker.io/aveshasystems
  kubeTally:
    enabled: ${var.settings.costManagement.enabled}
    postgresAddr: "${var.settings.costManagement.database.hostname}"
    postgresPort: ${var.settings.costManagement.database.port}
    postgresUser: "${var.settings.costManagement.database.username}"
    postgresPassword: "${var.settings.costManagement.database.password}"
    postgresDB: "${var.settings.costManagement.database.name}"

kubeslice:
  prometheus:
    enabled: true
  controller:
    endpoint: ${linode_lke_cluster.controller.api_endpoints[0]}

imagePullSecrets:
  username: ${var.settings.license.username}
  password: ${var.settings.license.password}
  email: ${var.settings.license.email}
EOT

  depends_on = [ linode_lke_cluster.controller ]
}

# Applies the controller manifest.
resource "null_resource" "applyController" {
  # Triggers only when it changed.
  triggers = {
    when = "${filemd5(local.applyControllerScriptFilename)}|${md5(local_file.controller.content)}}${var.settings.controller.region}"
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = local_sensitive_file.controllerKubeconfig.filename
      MANIFEST_FILENAME = local_file.controller.filename
      NODES_COUNT       = var.settings.controller.nodes.count
    }

    quiet   = true
    command = local.applyControllerScriptFilename
  }

  depends_on = [
    local_sensitive_file.controllerKubeconfig,
    local_file.controller
  ]
}

# Manager (UI) installation manifest.
resource "local_file" "manager" {
  filename = abspath(pathexpand("../etc/manager.yaml"))
  content = <<EOT
kubeslice:
  dashboard:
    enabled: true

imagePullSecrets:
  username: ${var.settings.license.username}
  password: ${var.settings.license.password}
  email: ${var.settings.license.email}
EOT

  depends_on = [ null_resource.applyController ]
}

# Applies the manager (UI) manifest in the controller.
resource "null_resource" "applyManager" {
  # Triggers only when it changed.
  triggers = {
    when = "${filemd5(local.applyManagerScriptFilename)}|${md5(local_file.manager.content)}"
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
    local_sensitive_file.controllerKubeconfig,
    local_file.manager
  ]
}

# Project manifest.
resource "local_file" "project" {
  filename = abspath(pathexpand("../etc/project.yaml"))
  content  = <<EOT
apiVersion: controller.kubeslice.io/v1alpha1
kind: Project

metadata:
  namespace: kubeslice-controller
  name: ${var.settings.controller.project}

spec:
  serviceAccount:
    readWrite:
      - admin
EOT

  depends_on = [ null_resource.applyManager ]
}

# Applies the project manifest in the controller.
resource "null_resource" "applyProject" {
  # Triggers only when it changed.
  triggers = {
    when = "${filemd5(local.applyProjectScriptFilename)}|${md5(local_file.project.content)}"
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = local_sensitive_file.controllerKubeconfig.filename
      MANIFEST_FILENAME = local_file.project.filename
      PROJECT_NAME      = var.settings.controller.project
    }

    quiet   = true
    command = local.applyProjectScriptFilename
  }

  depends_on = [
    local_sensitive_file.controllerKubeconfig,
    local_file.project
  ]
}

data "external" "fetchSliceNodeIp" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  program = [
    local.fetchSliceNodeIpScriptFilename,
    local_sensitive_file.workerKubeconfig[each.key].filename
  ]

  depends_on = [ local_sensitive_file.workerKubeconfig ]
}

# Worker manifest.
resource "local_file" "worker" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  filename = abspath(pathexpand("../etc/${each.key}-worker.yaml"))
  content  = <<EOT
apiVersion: controller.kubeslice.io/v1alpha1
kind: Cluster

metadata:
  name: ${each.key}
  namespace: kubeslice-${var.settings.controller.project}

spec:
  clusterProperty:
    geoLocation:
      cloudProvider: ${each.value.cloud}
      cloudRegion: ${each.value.region}
    telemetry:
      enabled: true
      telemetryProvider: prometheus
      endpoint: http://${data.external.fetchSliceNodeIp[each.key].result.ip}:32700
EOT

  depends_on = [
    null_resource.applyProject,
    data.external.fetchSliceNodeIp
  ]
}

# Applies the worker manifest in the worker.
resource "null_resource" "applyWorker" {
  for_each = { for worker in var.settings.workers: worker.identifier => worker }

  # Triggers only when it changed.
  triggers = {
    when = "${filemd5(local.applyWorkerScriptFilename)}|${md5(local_file.worker[each.key].content)}"
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = local_sensitive_file.controllerKubeconfig.filename
      MANIFEST_FILENAME = local_file.worker[each.key].filename
      PROJECT_NAME      = var.settings.controller.project
    }

    quiet   = true
    command = local.applyWorkerScriptFilename
  }

  depends_on = [
    local_sensitive_file.controllerKubeconfig,
    local_file.worker
  ]
}

# Creates the slice operator installation manifest.
resource "null_resource" "generateSliceOperator" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  triggers = {
    when = "${filemd5(local.generateSliceOperatorScriptFilename)}|${md5(local_file.worker[each.key].content)}"
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG                = local_sensitive_file.controllerKubeconfig.filename
      MANIFEST_FILENAME         = abspath(pathexpand("../etc/${each.key}-sliceOperator.yaml"))
      PROJECT_NAME              = var.settings.controller.project
      WORKER_CLUSTER_IDENTIFIER = each.key
      WORKER_CLUSTER_ENDPOINT   = (each.value.cloud == "Akamai" ? linode_lke_cluster.worker[each.key].api_endpoints[0] : azurerm_kubernetes_cluster.worker[each.key].kube_config[0].host)
      LICENSE_USERNAME          = var.settings.license.username
      LICENSE_PASSWORD          = var.settings.license.password
      LICENSE_EMAIL             = var.settings.license.email
    }

    quiet   = true
    command = local.generateSliceOperatorScriptFilename
  }

  depends_on = [
    local_sensitive_file.controllerKubeconfig,
    linode_lke_cluster.worker,
    azurerm_kubernetes_cluster.worker,
    null_resource.applyWorker
  ]
}

# Applies the slice operator manifest in the worker.
resource "null_resource" "applySliceOperator" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  # Triggers only when it changed.
  triggers = {
    when = "${filemd5(local.applySliceOperatorScriptFilename)}|${md5(local_file.worker[each.key].content)}"
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = local_sensitive_file.workerKubeconfig[each.key].filename
      MANIFEST_FILENAME = abspath(pathexpand("../etc/${each.key}-sliceOperator.yaml"))
    }

    quiet   = true
    command = local.applySliceOperatorScriptFilename
  }

  depends_on = [
    local_sensitive_file.workerKubeconfig,
    null_resource.applyIstio,
    null_resource.applyPrometheus,
    null_resource.generateSliceOperator
  ]
}

# Slice manifest.
resource "local_file" "slice" {
  filename = abspath(pathexpand("../etc/slice.yaml"))
  content  = <<EOT
apiVersion: controller.kubeslice.io/v1alpha1
kind: SliceConfig
metadata:
  name: ${var.settings.slice.identifier}
  namespace: kubeslice-${var.settings.controller.project}

spec:
  sliceSubnet: ${var.settings.slice.networkMask}
  sliceType: Application
  sliceGatewayProvider:
    sliceGatewayType: OpenVPN
    sliceCaType: Local
  sliceIpamType: Local

  clusters:
${trim(join("", local.sliceWorkers), "\n")}

  qosProfileDetails:
    queueType: HTB
    priority: 0
    tcType: BANDWIDTH_CONTROL
    bandwidthCeilingKbps: 10000000
    bandwidthGuaranteedKbps: 10000000
    dscpClass: AF11

  namespaceIsolationProfile:
    applicationNamespaces:
${trim(join("", local.sliceNamespaces), "\n")}
    isolationEnabled: false
    allowedNamespaces:
      - namespace: kube-system
        clusters:
          - "*"
${trim(join("", local.sliceNamespaces), "\n")}
EOT

  depends_on = [ null_resource.applySliceOperator ]
}

# Applies the slice manifest in the controller.
resource "null_resource" "applySlice" {
  # Triggers only when it changed.
  triggers = {
    when = "${filemd5(local.applySliceScriptFilename)}|${md5(local_file.slice.content)}"
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = local_sensitive_file.controllerKubeconfig.filename
      MANIFEST_FILENAME = local_file.slice.filename
      PROJECT_NAME      = var.settings.controller.project
    }

    quiet   = true
    command = local.applySliceScriptFilename
  }

  depends_on = [
    local_sensitive_file.controllerKubeconfig,
    local_file.slice,
    null_resource.applySliceOperator
  ]
}

# Fetches the node balancer IP of the slice in each worker.
data "external" "fetchSliceNodeBalancerIp" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  program = [
    local.fetchSliceNodeBalancerIpScriptFilename,
    local_sensitive_file.workerKubeconfig[each.key].filename,
    var.settings.slice.ingress
  ]

  depends_on = [
    local_sensitive_file.workerKubeconfig,
    null_resource.applySlice
  ]
}

# Generate a readme file.
resource "null_resource" "generateReadme" {
  # Triggers only when it changed.
  triggers = {
    when = filemd5(local.generateReadmeScriptFilename)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG   = local_sensitive_file.controllerKubeconfig.filename
      PROJECT_NAME = var.settings.controller.project
    }

    quiet   = true
    command = local.generateReadmeScriptFilename
  }

  depends_on = [
    local_sensitive_file.controllerKubeconfig,
    null_resource.applySlice
  ]
}

output "sliceNodeBalancerIp" {
  value = data.external.fetchSliceNodeBalancerIp
}