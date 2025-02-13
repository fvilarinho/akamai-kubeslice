# Required local variables.
locals {
  allowedIpv4 = concat(flatten([ for node in data.linode_instances.lkeNodes.instances : [ "${node.ip_address}/32", "${node.private_ip_address}/32" ]]),
                      flatten([ for scaleSet in data.azurerm_virtual_machine_scale_set.aksNodes : [ for node in scaleSet.instances : "${node.public_ip_address}/32" ] ]),
                      flatten([ for node in data.aws_instances.eksNodes : [ for publicIp in node.public_ips : "${publicIp}/32"] ]),
                              [ "${jsondecode(data.http.myIp.response_body).ip}/32" ])

  fetchNodeBalancersScriptFilename = abspath(pathexpand("../bin/fetchNodeBalancers.sh"))
}

# Fetches my local public IP to be allowed in the firewall.
data "http" "myIp" {
  url = "https://ipinfo.io"
}

data "external" "fetchNodeBalancers" {
  program = [
    local.fetchNodeBalancersScriptFilename,
    local_sensitive_file.controllerKubeconfig.filename
  ]

  depends_on = [
    linode_lke_cluster.controller,
    local_sensitive_file.controllerKubeconfig,
    null_resource.applyController,
    null_resource.applyManager
  ]
}

# Firewall definition.
resource "linode_firewall" "controllerNodes" {
  label           = "${var.settings.general.namespace}-cn-fw"
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
    label    = "allow-akamai-ips"
    protocol = "TCP"
    ports    = "22,443"
    ipv4     = [
      "172.236.119.4/30",
      "172.234.160.4/30",
      "172.236.94.4/30",
      "139.144.212.168/31",
      "172.232.23.164/31"
    ]
    ipv6     = [
      "2600:3c06::f03c:94ff:febe:162f/128",
      "2600:3c06::f03c:94ff:febe:16ff/128",
      "2600:3c06::f03c:94ff:febe:16c5/128",
      "2600:3c07::f03c:94ff:febe:16e6/128",
      "2600:3c07::f03c:94ff:febe:168c/128",
      "2600:3c07::f03c:94ff:febe:16de/128",
      "2600:3c08::f03c:94ff:febe:16e9/128",
      "2600:3c08::f03c:94ff:febe:1655/128",
      "2600:3c08::f03c:94ff:febe:16fd/128"
    ]
  }

  inbound {
    action   = "ACCEPT"
    label    = "allow-tcp-for-external-ips"
    protocol = "TCP"
    ipv4     = local.allowedIpv4
  }

  inbound {
    action   = "ACCEPT"
    label    = "allow-udp-for-external-ips"
    protocol = "UDP"
    ipv4     = local.allowedIpv4
  }

  linodes = local.lkeNodes

  depends_on = [
    data.http.myIp,
    data.linode_instances.lkeNodes,
    data.azurerm_virtual_machine_scale_set.aksNodes,
    data.aws_instances.eksNodes
  ]
}

resource "linode_firewall" "controllerNodeBalancers" {
  label           = "${var.settings.general.namespace}-cnb-fw"
  tags            = var.settings.general.tags
  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"

  inbound {
    action   = "ACCEPT"
    label    = "allowed-external-ips"
    protocol = "TCP"
    ports    = "443"
    ipv4     = concat(var.settings.firewall.allowedIps.ipv4, [ "${jsondecode(data.http.myIp.response_body).ip}/32" ])
    ipv6     = concat(var.settings.firewall.allowedIps.ipv6, [ "::1/128" ])
  }

  nodebalancers = [ data.external.fetchNodeBalancers.result.id ]

  depends_on = [
    data.http.myIp,
    data.external.fetchNodeBalancers
  ]
}