# Required local variables.
locals {
  applyIstioScriptFilename = abspath(pathexpand("../bin/applyIstio.sh"))
}

# Applies istio stack required by the slice operator.
resource "null_resource" "applyIstio" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  # Triggers only when it changed.
  triggers = {
    when = "${filemd5(local.applyIstioScriptFilename)}|${each.value.region}"
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local_sensitive_file.workerKubeconfig[each.key].filename
    }

    quiet   = true
    command = local.applyIstioScriptFilename
  }

  depends_on = [
    null_resource.applyWorker,
    local_sensitive_file.workerKubeconfig
  ]
}