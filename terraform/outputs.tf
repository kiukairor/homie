output "app_public_ip" {
  description = "homie-app public IP — point your domain A record here"
  value       = module.compute.app_public_ip
}

output "ai_public_ip" {
  description = "homie-ai public IP — SSH access only"
  value       = module.compute.ai_public_ip
}

output "app_private_ip" {
  description = "homie-app private IP — for inter-VM communication"
  value       = module.compute.app_private_ip
}

output "ai_private_ip" {
  description = "homie-ai private IP"
  value       = module.compute.ai_private_ip
}

output "argocd_initial_password_command" {
  description = "Command to retrieve ArgoCD initial admin password"
  value       = "ssh ubuntu@${module.compute.app_public_ip} 'kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d'"
}

output "tfstate_bucket" {
  description = "OCI bucket holding Terraform state"
  value       = module.storage.bucket_name
}
