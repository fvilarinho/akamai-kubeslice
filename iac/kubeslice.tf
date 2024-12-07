locals {
  applyControllerScriptFilename       = abspath(pathexpand("../bin/applyController.sh"))
  applyManagerScriptFilename          = abspath(pathexpand("../bin/applyManager.sh"))
  applyProjectScriptFilename          = abspath(pathexpand("../bin/applyProject.sh"))
  applyClusterScriptFilename          = abspath(pathexpand("../bin/applyCluster.sh"))
  generateSliceOperatorScriptFilename = abspath(pathexpand("../bin/generateSliceOperator.sh"))
  applySliceOperatorScriptFilename    = abspath(pathexpand("../bin/applySliceOperator.sh"))
  applySliceScriptFilename            = abspath(pathexpand("../bin/applySlice.sh"))
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
  controller:
    endpoint: ${linode_lke_cluster.controller.api_endpoints[0]}

imagePullSecrets:
  username: ${var.settings.license.username}
  password: ${var.settings.license.password}
  email: ${var.settings.general.email}
EOT

  depends_on = [ linode_lke_cluster.controller ]
}

resource "null_resource" "applyController" {
  triggers = {
    when = filemd5(local.applyControllerScriptFilename)
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

  depends_on = [ null_resource.applyController ]
}

resource "null_resource" "applyManager" {
  triggers = {
    when = filemd5(local.applyManagerScriptFilename)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = local_sensitive_file.controllerKubeconfig.filename
      MANIFEST_FILENAME = local_file.manager.filename
    }

    quiet   = true
    command = local.applyManagerScriptFilename
  }

  depends_on = [ local_file.manager ]
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

  depends_on = [ null_resource.applyManager ]
}

resource "null_resource" "applyProject" {
  triggers = {
    when = filemd5(local.applyProjectScriptFilename)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = local_sensitive_file.controllerKubeconfig.filename
      MANIFEST_FILENAME = local_file.project.filename
      PROJECT_NAME      = var.settings.general.namespace
    }

    quiet   = true
    command = local.applyProjectScriptFilename
  }

  depends_on = [ local_file.project ]
}

resource "local_file" "cluster" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  filename = abspath(pathexpand("../etc/${each.key}-cluster.yaml"))
  content  = <<EOT
apiVersion: controller.kubeslice.io/v1alpha1
kind: Cluster

metadata:
  name: ${each.key}
  namespace: kubeslice-${var.settings.general.namespace}

spec:
  networkInterface: eth0
  clusterProperty:
    geoLocation:
      cloudProvider: ${each.value.cloud}
      cloudRegion: ${each.value.nodes.region}
EOT

  depends_on = [
    linode_lke_cluster.workers,
    local_sensitive_file.workersKubeconfig
  ]
}

resource "null_resource" "applyClusters" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  triggers = {
    when = filemd5(local.applyClusterScriptFilename)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = local_sensitive_file.controllerKubeconfig.filename
      MANIFEST_FILENAME = local_file.cluster[each.key].filename
      PROJECT_NAME      = var.settings.general.namespace
    }

    quiet   = true
    command = local.applyClusterScriptFilename
  }

  depends_on = [ local_file.cluster ]
}

resource "null_resource" "generateSliceOperator" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  triggers = {
    when = filemd5(local.generateSliceOperatorScriptFilename)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG                = local_sensitive_file.controllerKubeconfig.filename
      MANIFEST_FILENAME         = abspath(pathexpand("../etc/${each.key}-sliceOperator.yaml"))
      PROJECT_NAME              = var.settings.general.namespace
      WORKER_CLUSTER_IDENTIFIER = each.key
      WORKER_CLUSTER_ENDPOINT   = linode_lke_cluster.workers[each.key].api_endpoints[0]
      LICENSE_USERNAME          = var.settings.license.username
      LICENSE_PASSWORD          = var.settings.license.password
      LICENSE_EMAIL             = var.settings.general.email
    }

    quiet   = true
    command = local.generateSliceOperatorScriptFilename
  }

  depends_on = [ null_resource.applyClusters ]
}

resource "null_resource" "applySliceOperator" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  triggers = {
    when = filemd5(local.applySliceOperatorScriptFilename)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = local_sensitive_file.workersKubeconfig[each.key].filename
      MANIFEST_FILENAME = abspath(pathexpand("../etc/${each.key}-sliceOperator.yaml"))
    }

    quiet   = true
    command = local.applySliceOperatorScriptFilename
  }

  depends_on = [ null_resource.generateSliceOperator ]
}

locals {
  sliceClusters   = [ for worker in var.settings.workers : <<EOT
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

resource "local_file" "slice" {
  filename = abspath(pathexpand("../etc/slice.yaml"))
  content  = <<EOT
apiVersion: controller.kubeslice.io/v1alpha1
kind: SliceConfig
metadata:
  name: ${var.settings.slice.identifier}
  namespace: kubeslice-${var.settings.general.namespace}

spec:
  sliceSubnet: ${var.settings.slice.networkMask}
  sliceType: Application
  sliceGatewayProvider:
    sliceGatewayType: OpenVPN
    sliceCaType: Local
  sliceIpamType: Local

  clusters:
${trim(join("", local.sliceClusters), "\n")}

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

resource "null_resource" "applySlice" {
  triggers = {
    when = filemd5(local.applySliceScriptFilename)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG        = local_sensitive_file.controllerKubeconfig.filename
      MANIFEST_FILENAME = local_file.slice.filename
      PROJECT_NAME      = var.settings.general.namespace
    }

    quiet   = true
    command = local.applySliceScriptFilename
  }

  depends_on = [ null_resource.applySliceOperator ]
}
