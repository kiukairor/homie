terraform {
  required_version = ">= 1.6"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }

  backend "s3" {}
}

provider "oci" {
  tenancy_ocid     = var.oci_tenancy_ocid
  user_ocid        = var.oci_user_ocid
  fingerprint      = var.oci_fingerprint
  private_key_path = var.oci_private_key_path
  region           = var.oci_region
}

module "storage" {
  source         = "./modules/storage"
  compartment_id = var.oci_compartment_id
  namespace      = var.oci_namespace
}

module "network" {
  source         = "./modules/network"
  compartment_id = var.oci_compartment_id
  vcn_cidr       = "10.0.0.0/16"
  subnet_cidr    = "10.0.0.0/24"
}

module "compute" {
  source         = "./modules/compute"
  compartment_id = var.oci_compartment_id
  subnet_id      = module.network.subnet_id
  ssh_public_key = var.ssh_public_key

  app_user_data = templatefile("${path.module}/cloud-init/homie-app.yaml.tpl", {
    k3s_version       = var.k3s_version
    github_repo       = var.github_repo
    argocd_version    = var.argocd_version
    domain            = var.domain
    certmanager_email = var.certmanager_email
  })

  ai_user_data = templatefile("${path.module}/cloud-init/homie-ai.yaml.tpl", {
    k3s_version    = var.k3s_version
    app_private_ip = module.compute.app_private_ip
  })
}
