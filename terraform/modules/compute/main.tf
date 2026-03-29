terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }
}

variable "compartment_id"  {}
variable "subnet_id"        {}
variable "ssh_public_key"   {}
variable "app_user_data"    {}
variable "ai_user_data"     {}

data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

locals {
  ubuntu_arm_image_id = data.oci_core_images.ubuntu_arm.images[0].id
  # Try AD-2 index 1, change to 0 or 2 if still out of capacity
  ad_index = 1
}

resource "oci_core_instance" "homie_app" {
  compartment_id      = var.compartment_id
  display_name        = "homie-app"
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[local.ad_index].name
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 2
    memory_in_gbs = 12
  }

  source_details {
    source_type             = "image"
    source_id               = local.ubuntu_arm_image_id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = true
    hostname_label   = "homie-app"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(var.app_user_data)
  }
}

resource "oci_core_instance" "homie_ai" {
  compartment_id      = var.compartment_id
  display_name        = "homie-ai"
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[local.ad_index].name
  shape               = "VM.Standard.A1.Flex"
  depends_on          = [oci_core_instance.homie_app]

  shape_config {
    ocpus         = 2
    memory_in_gbs = 12
  }

  source_details {
    source_type             = "image"
    source_id               = local.ubuntu_arm_image_id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = true
    hostname_label   = "homie-ai"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(var.ai_user_data)
  }
}

output "app_public_ip"  { value = oci_core_instance.homie_app.public_ip }
output "ai_public_ip"   { value = oci_core_instance.homie_ai.public_ip }
output "app_private_ip" { value = oci_core_instance.homie_app.private_ip }
output "ai_private_ip"  { value = oci_core_instance.homie_ai.private_ip }

output "k3s_ca_cert" {
  value     = ""
  sensitive = true
}

output "k3s_token" {
  value     = ""
  sensitive = true
}
