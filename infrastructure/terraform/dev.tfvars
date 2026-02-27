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
acr_sku                     = "Premium" # Must stay Premium with existing private endpoints
enable_acr_private_endpoint = true

# API Management
apim_sku                     = "StandardV2" # Existing deployed SKU; in-place downgrade unsupported
enable_apim_private_endpoint = true

# Microsoft Foundry
enable_foundry_private_endpoint = true
foundry_sku                     = "S0"
foundry_project_name            = "main-project"

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
  project         = "azlz"
  cost_center     = "engineering"
  created_by      = "terraform"
  environment     = "dev"
}
