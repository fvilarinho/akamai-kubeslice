# Required local variables.
locals {
  fetchWorkerNodeBalancerIpScriptFilename = abspath(pathexpand("../bin/fetchWorkerNodeBalancerIp.sh"))
}

# Creates the GTM domain.
resource "akamai_gtm_domain" "default" {
  name     = "${var.settings.dns.domain}.akadns.net"
  type     = "weighted"
  contract = var.settings.gtm.contract
  group    = var.settings.gtm.group
}

# Creates the GTM datacenter for the workers clusters.
resource "akamai_gtm_datacenter" "worker" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker}

  domain   = akamai_gtm_domain.default.name
  nickname = "${each.key} - ${each.value.cloud} - ${each.value.region}"

  depends_on = [ akamai_gtm_domain.default ]
}

# Fetches the node balancer IP of the worker clusters.
data "external" "fetchWorkerNodeBalancerIp" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker }

  program = [
    local.fetchWorkerNodeBalancerIpScriptFilename,
    local_sensitive_file.workerKubeconfig[each.key].filename,
    var.settings.slice.ingress
  ]

  depends_on = [ local_sensitive_file.workerKubeconfig ]
}

# Creates the GTM property.
resource "akamai_gtm_property" "worker" {
  domain                 = akamai_gtm_domain.default.name
  name                   = var.settings.slice.identifier
  score_aggregation_type = "median"
  type                   = "weighted-round-robin"
  handout_mode           = "normal"
  handout_limit          = length(var.settings.workers)
  dynamic_ttl            = 30

  dynamic "traffic_target" {
    for_each = { for worker in var.settings.workers : worker.identifier => worker}

    content {
      enabled       = true
      datacenter_id = akamai_gtm_datacenter.worker[traffic_target.key].datacenter_id
      servers       = [ data.external.fetchWorkerNodeBalancerIp[traffic_target.key].result.ip ]
      weight        = traffic_target.value.trafficPercentage
    }
  }

  liveness_test {
    name                 = "http"
    test_object_protocol = "TCP"
    test_object_port     = 80
    test_interval        = 10
    test_timeout         = 1
  }

  liveness_test {
    name                 = "https"
    test_object_protocol = "TCP"
    test_object_port     = 443
    test_interval        = 10
    test_timeout         = 1
  }

  depends_on = [
    akamai_gtm_domain.default,
    akamai_gtm_datacenter.worker,
    data.external.fetchWorkerNodeBalancerIp
  ]
}