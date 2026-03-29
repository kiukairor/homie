# OCI Auth
variable "oci_tenancy_ocid"     { description = "OCI tenancy OCID" }
variable "oci_user_ocid"        { description = "OCI user OCID" }
variable "oci_fingerprint"      { description = "API key fingerprint" }
variable "oci_private_key_path" { description = "Path to OCI API private key" }
variable "oci_region"           { description = "OCI region e.g. uk-london-1" }
variable "oci_compartment_id"   { description = "Compartment OCID (root or custom)" }
variable "oci_namespace"        { description = "OCI object storage namespace" }

# OCI S3-compat credentials for Terraform state bucket
variable "oci_access_key"  { description = "Customer secret key access key" }
variable "oci_secret_key"  { description = "Customer secret key secret" }

# SSH
variable "ssh_public_key" { description = "Public key for VM SSH access" }

# App config
variable "domain"            { description = "Your public domain e.g. homie.example.com" }
variable "certmanager_email" { description = "Email for Let's Encrypt cert notifications" }
variable "github_repo"       {
  description = "GitHub repo URL"
  default     = "https://github.com/kiukairor/homie.git"
}

# Versions — pin these for reproducibility
variable "k3s_version" {
  description = "k3s version"
  default     = "v1.30.2+k3s1"
}
variable "argocd_version" {
  description = "ArgoCD Helm chart version"
  default     = "7.3.4"
}
