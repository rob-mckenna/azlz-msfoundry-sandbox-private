# Development Environment - Azure Landing Zone
# Used for: Low-cost testing and development

environment  = "dev"
location     = "eastus2"
project_name = "azlz"

# Compute
max_replicas = 3
min_replicas = 1

# Container Apps
enable_container_app_external = false

# ACR
acr_sku                     = "Standard" # Cost optimization for dev (no private endpoints)
enable_acr_private_endpoint = false

# API Management
apim_sku                     = "Developer" # Cost optimization for dev
enable_apim_private_endpoint = false

# Microsoft Foundry
enable_foundry_private_endpoint = true
foundry_sku                     = "S0"
foundry_project_name            = "dev-project"

# CI/CD
enable_cicd_runner               = true
github_runner_registration_token = "" # Set via GitHub secret
github_runner_url                = "" # Set via GitHub secret
runner_container_image           = "azlzacr2cbd.azurecr.io/github-actions-runner:1.0"

# Windows VM Configuration
windows_vm_size = "Standard_D4s_v5"
# windows_admin_password = ""  # Set via GitHub secret or environment variable

# Tags
tags = {
  environment     = "dev"
  managed_by      = "terraform"
  github_workflow = "deploy-infrastructure"
}
