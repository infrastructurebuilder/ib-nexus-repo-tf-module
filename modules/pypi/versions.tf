terraform {
  required_version = ">= 1.3"

  required_providers {
    nexus = {
      source  = "datadrivers/nexus"
      version = ">= 2.6.0"
    }
  }
}
