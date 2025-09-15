terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm",
      version = "~> 2.0.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes",
      version = "~> 1.13.3"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack",
      version = "~> 1.53.0"
    }
  }
  required_version = ">= 0.13"
}
