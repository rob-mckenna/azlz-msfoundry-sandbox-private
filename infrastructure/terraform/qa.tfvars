# QA Environment - Azure Landing Zone
# Used for: Quality assurance and pre-production validation

environment = "qa"
location    = "eastus"
project_name = "azlz"

# Compute
vm_size = "Standard_B2s"
max_replicas = 5
min_replicas = 1

# Container Apps
enable_container_app_external = false

# ACR
acr_sku = "Premium"  # Use Premium for private endpoints
enable_acr_private_endpoint = true

# API Management
apim_sku = "StandardV2"  # Use prod-grade SKU for validation
enable_apim_private_endpoint = true

# CI/CD
enable_cicd_runner = true
github_runner_registration_token = ""  # Set via GitHub secret
github_runner_url = ""                 # Set via GitHub secret
runner_container_image = "ghcr.io/myoats/actions-runner:latest"

# SSH Public Key (required - replace with your key)
ssh_public_key = "ssh-rsa AAAA..."

# Windows VM Configuration
windows_vm_size = "Standard_D4s_v5"
# windows_admin_password = ""  # Set via GitHub secret or environment variable

# Tags
tags = {
  environment = "qa"
  managed_by  = "terraform"
  github_workflow = "deploy-infrastructure"
}
