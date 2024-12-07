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
      KUBECONFIG = local_sensitive_file.workersKubeconfig[each.key].filename
    }

    quiet   = true
    command = local.applyIstioScriptFilename
  }

  depends_on = [
    linode_lke_cluster.workers,
    local_sensitive_file.workersKubeconfig
  ]
}