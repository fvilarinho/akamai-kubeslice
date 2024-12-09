terraform {
  # Saves the state in a remote backend (S3 Bucket).
  backend "s3" {
    bucket                      = "fvilarin-devops"
    key                         = "akamai-kubeslice.tfstate"
    region                      = "us-east-1"
    endpoint                    = "us-east-1.linodeobjects.com"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
  }

  # Definition of required providers.
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

# Definition of Akamai Cloud Computing provider.
provider "linode" {
  token = var.settings.general.token
}