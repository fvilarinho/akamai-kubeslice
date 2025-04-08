# Fetches the attributes of the DNS domain.
data "linode_domain" "slice" {
  domain = var.settings.slice.gtm.domain
}

# Adds the DNS entry for GTM.
resource "linode_domain_record" "slice" {
  domain_id   = data.linode_domain.slice.id
  name        = var.settings.slice.identifier
  record_type = "CNAME"
  target      = "${akamai_gtm_property.slice.name}.${akamai_gtm_property.slice.domain}"
  ttl_sec     = 30

  depends_on = [
    data.linode_domain.slice,
    akamai_gtm_property.slice
  ]
}