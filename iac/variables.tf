variable "settings" {
  default = {
    general = {
      domain     = "<your-domain>"
      email      = "<your-email>"
      token      = "<token>"
      namespace  = "multicloud"
      tags       = [ "demo", "kubeslice" ]
    }

    license = {
      username = "<username>"
      password = "<password>"
    }

    controller = {
      identifier = "controller"
      nodes      = {
        type   = "g6-standard-4"
        region = "<region>"
        count  = 2
      }
    }

    workers = [
      {
        identifier = "worker1"
        cloud      = "Akamai"
        nodes      = {
          type   = "g6-standard-4"
          region = "<region>"
          count  = 3
        }
      }
    ]

    slice = {
      identifier  = "demo"
      networkMask = "10.10.0.0/16"
      namespaces  = [ "frontend", "backend", "database" ]
    }

    firewall = {
      allowedIps = {
        ipv4 = ["0.0.0.0/0 "]
        ipv6 = []
      }
    }
  }
}