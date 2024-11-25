terraform {
  backend "s3" {
    bucket                      = "fvilarin-devops"
    key                         = "akamai-kubeslice.tfstate"
    region                      = "us-east-1"
    endpoint                    = "us-east-1.linodeobjects.com"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
  }

  required_providers {
    linode = {
      source = "linode/linode"
    }

    null = {
      source = "hashicorp/null"
    }

    random = {
      source = "hashicorp/random"
    }
  }
}

provider "linode" {
  token = var.settings.general.token
}