variable "sliceNodeBalancerIp" {}

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
  }
}

variable "settings" {
  default = {
    workers = [
      {
        identifier        = "worker1"
        cloud             = "<cloud>"
        region            = "<region>"
        trafficPercentage = 100
      }
    ]

    slice = {
      identifier  = "demo"

      gtm = {
        contract = "<contract>"
        group    = "<group>"
        domain   = "<domain>"
      }
    }
  }
}