terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }
}

variable "compartment_id" {}
variable "namespace"       {}

resource "oci_objectstorage_bucket" "tfstate" {
  compartment_id = var.compartment_id
  namespace      = var.namespace
  name           = "homie-tfstate"
  access_type    = "NoPublicAccess"
  versioning     = "Enabled"
}

output "bucket_name" { value = oci_objectstorage_bucket.tfstate.name }
