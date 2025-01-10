# Required local variables.
locals {
  allowedIps = concat(flatten([ for node in data.linode_instances.lkeNodes.instances : [ "${node.ip_address}/32", "${node.private_ip_address}/32" ]]),
                      flatten([ for scaleSet in data.azurerm_virtual_machine_scale_set.aksNodes : [ for node in scaleSet.instances : "${node.public_ip_address}/32" ] ]),
                      flatten([ for node in data.aws_instances.eksNodes : [ for publicIp in node.public_ips : "${publicIp}/32"] ]),
                              [ "${jsondecode(data.http.myIp.response_body).ip}/32" ])

  allowedIpv4 = concat(var.settings.firewall.allowedIps.ipv4, local.allowedIps)
}

# Fetches my local public IP to be allowed in the firewall.
data "http" "myIp" {
  url = "https://ipinfo.io"
}

# Firewall definition.
resource "linode_firewall" "default" {
  label           = "${var.settings.general.namespace}-firewall"
  tags            = var.settings.general.tags
  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"

  # Akamai compliance rule.
  inbound {
    action   = "ACCEPT"
    label    = "allow-icmp"
    protocol = "ICMP"
    ipv4     = [ "0.0.0.0/0" ]
  }

  # Akamai compliance rule.
  inbound {
    action   = "ACCEPT"
    label    = "allowed-cluster-nodeports-udp"
    protocol = "IPENCAP"
    ipv4     = [ "192.168.128.0/17" ]
  }

  # Akamai compliance rule.
  inbound {
    action   = "ACCEPT"
    label    = "allowed-kubelet-health-checks"
    protocol = "TCP"
    ports    = "10250, 10256"
    ipv4     = [ "192.168.128.0/17" ]
  }

  # Akamai compliance rule.
  inbound {
    action   = "ACCEPT"
    label    = "allowed-lke-wireguard"
    protocol = "UDP"
    ports    = "51820"
    ipv4     = [ "192.168.128.0/17" ]
  }

  # Akamai compliance rule.
  inbound {
    action   = "ACCEPT"
    label    = "allowed-cluster-dns-tcp"
    protocol = "TCP"
    ports    = "53"
    ipv4     = [ "192.168.128.0/17" ]
  }

  # Akamai compliance rule.
  inbound {
    action   = "ACCEPT"
    label    = "allowed-cluster-dns-udp"
    protocol = "UDP"
    ports    = "53"
    ipv4     = [ "192.168.128.0/17" ]
  }

  # Akamai compliance rule.
  inbound {
    action   = "ACCEPT"
    label    = "allowed-nodebalancers-tcp"
    protocol = "TCP"
    ports    = "30000-32767"
    ipv4     = [ "192.168.255.0/24" ]
  }

  # Akamai compliance rule.
  inbound {
    action   = "ACCEPT"
    label    = "allowed-nodebalancers-udp"
    protocol = "UDP"
    ports    = "30000-32767"
    ipv4     = [ "192.168.255.0/24" ]
  }

  # Akamai compliance rule.
  inbound {
    action   = "ACCEPT"
    label    = "allowed-ips"
    protocol = "TCP"
    ipv4     = local.allowedIpv4
    ipv6     = var.settings.firewall.allowedIps.ipv6
  }

  # Akamai compliance rule.
  inbound {
    action   = "ACCEPT"
    label    = "allowed-ips"
    protocol = "UDP"
    ipv4     = local.allowedIpv4
    ipv6     = var.settings.firewall.allowedIps.ipv6
  }

  linodes = local.lkeNodes

  depends_on = [
    data.http.myIp,
    data.linode_instances.lkeNodes,
    data.azurerm_virtual_machine_scale_set.aksNodes,
    data.aws_instances.eksNodes
  ]
}