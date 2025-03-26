variable "credentials" {
  default = {
    edgegrid = {
      accountKey   = "<account>"
      host         = "<host>"
      accessToken  = "<accessToken>"
      clientToken  = "<clientToken>"
      clientSecret = "<clientSecret>"
    }

    linode = {
      token = "<token>"
    }

    azure = {
      subscriptionId = "<subscriptionId>"
      tenantId       = "<tenantId>"
      clientId       = "<clientId>"
      clientSecret   = "<clientSecret>"
    }
  }
}

variable "settings" {
  default = {
    controller = {
      project    = "multicloud"
      identifier = "controller"
      tags       = [ "demo", "kubeslice", "controller" ]
      region     = "<region>"

      nodes = {
        type  = "g6-standard-4"
        count = 2
      }
    }

    workers = [
      {
        identifier = "worker1"
        tags       = [ "demo", "kubeslice", "worker" ]
        cloud      = "Akamai"
        region     = "<region>"

        nodes = {
          type  = "g6-standard-4"
          count = 3
        }

        trafficPercentage = 100
      }
    ]

    slice = {
      namespaces  = [ "frontend", "backend", "database" ]
      identifier  = "demo"
      networkMask = "10.10.0.0/16"

      gtm = {
        contract = "<contract>"
        group    = "<group>"
        domain   = "<domain>"
        ingress  = "frontend"
      }
    }

    costManagement = {
      enabled = true

      database = {
        name     = "<name>"
        hostname = "<hostname>"
        port     = 5432
        username = "<username>"
        password = "<password>"
      }
    }

    license = {
      email    = "<your-email>"
      username = "<username>"
      password = "<password>"
    }
  }
}