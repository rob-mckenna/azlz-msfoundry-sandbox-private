location            = "eastus2"
environment         = "dev"
project_name        = "azlz"
resource_group_name = ""

# Network Configuration
vnet_address_space           = "10.0.0.0/16"
acr_subnet_address_space     = "10.0.1.0/24"
aca_subnet_address_space     = "10.0.2.0/24"
jumpbox_subnet_address_space = "10.0.3.0/24"
bastion_subnet_address_space = "10.0.4.0/24"
apim_subnet_address_space    = "10.0.5.0/24"

# ACR Configuration
acr_sku                     = "Premium"
acr_admin_enabled           = false
enable_acr_private_endpoint = true

# API Management Configuration
apim_sku                      = "StandardV2"
apim_capacity                 = 1
# Note: Set apim_publisher_name and apim_publisher_email via:
#   - Environment variables: TF_VAR_apim_publisher_name, TF_VAR_apim_publisher_email
#   - CLI flags: -var="apim_publisher_name=..." -var="apim_publisher_email=..."
#   - Local config: Use local.tfvars file (not committed to git)
enable_apim_private_endpoint  = true
enable_aca_private_endpoint   = true
enable_container_app_external = false # True private endpoint: only internal access

# CI/CD Runner Configuration (GitHub Actions self-hosted)
enable_cicd_runner             = false  # Set to true to enable GitHub Actions runner
github_runner_registration_token = ""   # Set to your GitHub runner registration token
github_runner_url              = ""     # Set to your GitHub repo/org URL (e.g., https://github.com/myorg/myrepo)
runner_container_image         = "ghcr.io/myoats/actions-runner:latest"

# VM Configuration
vm_size            = "Standard_B2s"
admin_username     = "azureuser"
vm_image_publisher = "Canonical"
vm_image_offer     = "0001-com-ubuntu-server-jammy"
vm_image_sku       = "22_04-lts-gen2"
vm_image_version   = "latest"

# Replace with your SSH public key
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDR3b7fZ5N7VvN8..."

# Windows VM Configuration
windows_vm_size            = "Standard_D4s_v5"
windows_admin_password     = ""  # Set a strong password (12-123 chars, must include uppercase, lowercase, number, and special char)
windows_vm_image_publisher = "MicrosoftWindowsServer"
windows_vm_image_offer     = "WindowsServer"
windows_vm_image_sku       = "2022-datacenter-azure-edition"
windows_vm_image_version   = "latest"

# ACA Configuration
aca_workload_profile = "Consumption"

# Container Configuration
container_port   = 8080
container_cpu    = "0.5"
container_memory = "1Gi"
min_replicas     = 1
max_replicas     = 5

# Log Analytics
log_analytics_retention_days = 30

# Tags
tags = {
  environment = "dev"
  project     = "azlz"
  created_by  = "terraform"
  cost_center = "engineering"
}
