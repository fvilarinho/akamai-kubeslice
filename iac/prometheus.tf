locals {
  applyPrometheusScriptFilename = abspath(pathexpand("../bin/applyPrometheus.sh"))
}

resource "null_resource" "applyPrometheus" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  triggers = {
    when = filemd5(local.applyPrometheusScriptFilename)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local_sensitive_file.workersKubeconfig[each.key].filename
    }

    quiet   = true
    command = local.applyPrometheusScriptFilename
  }

  depends_on = [
    linode_lke_cluster.workers,
    local_sensitive_file.workersKubeconfig
  ]
}