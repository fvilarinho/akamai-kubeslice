# Fetches the attributes of the DNS domain.
data "linode_domain" "default" {
  domain = var.settings.dns.domain
}

# Adds the DNS entry for GTM.
resource "linode_domain_record" "default" {
  domain_id   = data.linode_domain.default.id
  name        = var.settings.slice.identifier
  record_type = "CNAME"
  target      = "${akamai_gtm_property.worker.name}.${akamai_gtm_property.worker.domain}"
  ttl_sec     = 30

  depends_on = [
    data.linode_domain.default,
    akamai_gtm_property.worker
  ]
}