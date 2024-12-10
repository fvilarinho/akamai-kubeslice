variable "settings" {
  default = {
    general = {
      domain = "<your-domain>"
      email  = "<your-email>"
      token  = "<token>"
      tags   = [ "demo", "kubeslice" ]
    }

    license = {
      username = "<username>"
      password = "<password>"
    }

    controller = {
      namespace  = "multicloud"
      identifier = "controller"
      region     = "<region>"
      nodes      = {
        type   = "g6-standard-4"
        count  = 2
      }
    }

    workers = [
      {
        identifier = "worker1"
        cloud      = "Akamai"
        region     = "<region>"
        nodes      = {
          type   = "g6-standard-4"
          count  = 3
        }
      }
    ]

    slice = {
      namespaces  = [ "frontend", "backend", "database" ]
      identifier  = "demo"
      networkMask = "10.10.0.0/16"
    }

    costManagement = {
      enabled  = true
      database = {
        name     = "<name>"
        hostname = "<hostname>"
        port     = 5432
        username = "<username>"
        password = "<password>"
      }
    }

    firewall = {
      allowedIps = {
        ipv4 = ["0.0.0.0/0 "]
        ipv6 = []
      }
    }
  }
}