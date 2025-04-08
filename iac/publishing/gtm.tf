data "akamai_gtm_domain" "slice" {
  name = "${var.settings.slice.gtm.domain}.akadns.net"
}

# Creates the GTM datacenter for the workers clusters.
resource "akamai_gtm_datacenter" "slice" {
  for_each = { for worker in var.settings.workers : worker.identifier => worker}

  domain   = data.akamai_gtm_domain.slice.name
  nickname = "${each.key} - ${each.value.cloud} - ${each.value.region}"

  depends_on = [ data.akamai_gtm_domain.slice ]
}

# Creates the GTM property for the slice.
resource "akamai_gtm_property" "slice" {
  domain                 = data.akamai_gtm_domain.slice.name
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
      datacenter_id = akamai_gtm_datacenter.slice[traffic_target.key].datacenter_id
      servers       = [ var.sliceNodeBalancerIp[traffic_target.key].result.ip ]
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
    data.akamai_gtm_domain.slice,
    akamai_gtm_datacenter.slice,
    var.sliceNodeBalancerIp
  ]
}