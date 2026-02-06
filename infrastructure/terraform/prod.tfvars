# Production Environment - Azure Landing Zone
# Used for: Production workloads - requires high availability and security

environment = "prod"
location    = "eastus"
project_name = "azlz"

# Compute
vm_size = "Standard_D2s_v3"  # Larger VM for production
max_replicas = 10
min_replicas = 2

# Container Apps
enable_container_app_external = false  # Keep internal by default

# ACR
acr_sku = "Premium"  # Required for private endpoints
enable_acr_private_endpoint = true

# API Management
apim_sku = "StandardV2"  # Production-ready SKU
enable_apim_private_endpoint = true

# CI/CD
enable_cicd_runner = true
github_runner_registration_token = ""  # Set via GitHub secret
github_runner_url = ""                 # Set via GitHub secret
runner_container_image = "ghcr.io/myoats/actions-runner:latest"

# SSH Public Key (required - set to your production key)
ssh_public_key = "ssh-rsa AAAA..."

# Windows VM Configuration
windows_vm_size = "Standard_D4s_v5"
# windows_admin_password = ""  # Set via GitHub secret or environment variable

# Tags
tags = {
  environment = "prod"
  managed_by  = "terraform"
  github_workflow = "deploy-infrastructure"
  cost_center = ""  # Add your cost center
  owner       = ""  # Add owner contact
}
