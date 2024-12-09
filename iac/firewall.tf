# Required local variables.
locals {
  nodesToBeProtected = concat([ for node in linode_lke_cluster.controller.pool[0].nodes : node.instance_id ],
                              flatten([ for worker in var.settings.workers : [ for node in linode_lke_cluster.worker[worker.identifier].pool[0].nodes : node.instance_id ]]))

  allowedIps = concat(flatten([ for node in data.linode_instances.clustersNodes.instances : [ "${node.ip_address}/32", "${node.private_ip_address}/32" ]]),
                              [ "${jsondecode(data.http.myIp.response_body).ip}/32" ])

  allowedIpv4 = concat(var.settings.firewall.allowedIps.ipv4, local.allowedIps)
}

# Fetches my local public IP to be allowed in the firewall.
data "http" "myIp" {
  url = "https://ipinfo.io"
}

# Fetches all IPs (private and public) of the clusters' nodes to be allowed in the firewall.
data "linode_instances" "clustersNodes" {
  filter {
    name   = "id"
    values = local.nodesToBeProtected
  }

  depends_on = [
    linode_lke_cluster.controller,
    linode_lke_cluster.worker
  ]
}

# Firewall definition.
resource "linode_firewall" "default" {
  label           = "${var.settings.controller.namespace}-firewall"
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

  linodes = local.nodesToBeProtected

  depends_on = [
    data.http.myIp,
    data.linode_instances.clustersNodes,
    null_resource.applySlice
  ]
}