terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }
}

variable "compartment_id" {}
variable "vcn_cidr"        { default = "10.0.0.0/16" }
variable "subnet_cidr"     { default = "10.0.0.0/24" }

resource "oci_core_vcn" "homie" {
  compartment_id = var.compartment_id
  cidr_block     = var.vcn_cidr
  display_name   = "homie-vcn"
  dns_label      = "homie"
}

resource "oci_core_internet_gateway" "homie" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.homie.id
  display_name   = "homie-igw"
  enabled        = true
}

resource "oci_core_route_table" "homie" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.homie.id
  display_name   = "homie-rt"
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.homie.id
  }
}

resource "oci_core_security_list" "homie_app" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.homie.id
  display_name   = "homie-app-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = var.subnet_cidr
    tcp_options {
      min = 6443
      max = 6443
    }
  }
  ingress_security_rules {
    protocol = "17"
    source   = var.subnet_cidr
    udp_options {
      min = 8472
      max = 8472
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = var.subnet_cidr
    tcp_options {
      min = 10250
      max = 10250
    }
  }
}

resource "oci_core_security_list" "homie_ai" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.homie.id
  display_name   = "homie-ai-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    protocol = "17"
    source   = var.subnet_cidr
    udp_options {
      min = 8472
      max = 8472
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = var.subnet_cidr
    tcp_options {
      min = 10250
      max = 10250
    }
  }
}

resource "oci_core_subnet" "homie" {
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.homie.id
  cidr_block        = var.subnet_cidr
  display_name      = "homie-subnet"
  dns_label         = "homiesubnet"
  route_table_id    = oci_core_route_table.homie.id
  security_list_ids = [oci_core_security_list.homie_app.id]
}

output "subnet_id"       { value = oci_core_subnet.homie.id }
output "homie_app_sl_id" { value = oci_core_security_list.homie_app.id }
output "homie_ai_sl_id"  { value = oci_core_security_list.homie_ai.id }
