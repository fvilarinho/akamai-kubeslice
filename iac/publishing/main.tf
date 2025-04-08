terraform {
  # Definition of required providers.
  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = "6.6.0"
    }

    linode = {
      source = "linode/linode"
      version = "2.31.1"
    }

    null = {
      source = "hashicorp/null"
      version = "3.2.3"
    }

    local = {
      source = "hashicorp/local"
      version = "2.5.2"
    }

    external = {
      source = "hashicorp/external"
      version = "2.3.4"
    }
  }
}