# Required local variables.
locals {
  applyPrometheusScriptFilename = abspath(pathexpand("../bin/applyPrometheus.sh"))
}

# Applies prometheus stack required by the slice operator.
resource "null_resource" "applyPrometheus" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  # Triggers only when it changed.
  triggers = {
    when = filemd5(local.applyPrometheusScriptFilename)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local_sensitive_file.workerKubeconfig[each.key].filename
    }

    quiet   = true
    command = local.applyPrometheusScriptFilename
  }

  depends_on = [
    null_resource.applyWorker,
    local_sensitive_file.workerKubeconfig
  ]
}