locals {
  applyIstioScriptFilename = abspath(pathexpand("../bin/applyIstio.sh"))
}

resource "null_resource" "applyIstio" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  triggers = {
    when = filemd5(local.applyIstioScriptFilename)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local_sensitive_file.workerKubeconfig[each.key].filename
    }

    quiet   = true
    command = local.applyIstioScriptFilename
  }

  depends_on = [
    linode_lke_cluster.worker,
    local_sensitive_file.workerKubeconfig
  ]
}