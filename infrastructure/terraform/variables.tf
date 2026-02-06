variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "azlz"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = ""
}

# Network Configuration
variable "vnet_address_space" {
  description = "CIDR block for virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "acr_subnet_address_space" {
  description = "CIDR block for ACR subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "aca_subnet_address_space" {
  description = "CIDR block for Container Apps subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "jumpbox_subnet_address_space" {
  description = "CIDR block for jumpbox subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "bastion_subnet_address_space" {
  description = "CIDR block for Bastion subnet"
  type        = string
  default     = "10.0.4.0/24"
}

variable "apim_subnet_address_space" {
  description = "CIDR block for API Management subnet"
  type        = string
  default     = "10.0.5.0/24"
}

variable "cicd_subnet_address_space" {
  description = "CIDR block for CI/CD subnet"
  type        = string
  default     = "10.0.6.0/24"
}

# CI/CD Runner Configuration
variable "enable_cicd_runner" {
  description = "Enable self-hosted CI/CD runner using Container Apps Jobs"
  type        = bool
  default     = false
}

variable "github_runner_registration_token" {
  description = "GitHub Runner registration token (from GitHub org/repo settings)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_runner_url" {
  description = "GitHub repository or organization URL for runner registration"
  type        = string
  default     = ""
}

variable "runner_container_image" {
  description = "Container image for GitHub Actions runner"
  type        = string
  default     = "ghcr.io/myoats/actions-runner:latest"
}

# ACR Configuration
variable "acr_sku" {
  description = "SKU for Container Registry (Basic, Standard, Premium). Premium required for private endpoints."
  type        = string
  default     = "Premium"
}

variable "acr_admin_enabled" {
  description = "Enable admin user for ACR"
  type        = bool
  default     = false
}

variable "enable_acr_private_endpoint" {
  description = "Enable private endpoint for ACR"
  type        = bool
  default     = true
}

# API Management Configuration
variable "apim_sku" {
  description = "SKU for API Management (StandardV2, PremiumV2)"
  type        = string
  default     = "StandardV2"
}

variable "apim_capacity" {
  description = "Number of scale units for API Management"
  type        = number
  default     = 1
}

variable "apim_publisher_name" {
  description = "Publisher name for API Management"
  type        = string
  default     = "Your Organization"
}

variable "apim_publisher_email" {
  description = "Publisher email for API Management"
  type        = string
  default     = "admin@yourdomain.com"
}

variable "enable_apim_private_endpoint" {
  description = "Enable private endpoint for API Management"
  type        = bool
  default     = true
}

variable "enable_apim_logging" {
  description = "Enable Application Insights logging for API Management"
  type        = bool
  default     = true
}

variable "apim_diagnostic_retention_days" {
  description = "Retention in days for APIM diagnostic logs"
  type        = number
  default     = 30
}

variable "enable_aca_private_endpoint" {
  description = "Enable private endpoint for Container Apps environment"
  type        = bool
  default     = true
}

variable "enable_container_app_external" {
  description = "Enable external ingress for Container App (disable for pure private endpoint)"
  type        = bool
  default     = false
}

# VM Configuration
variable "vm_size" {
  description = "VM size for jumpbox"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for jumpbox VM"
  type        = string
  default     = "azureuser"
}

variable "vm_image_publisher" {
  description = "VM image publisher"
  type        = string
  default     = "Canonical"
}

variable "vm_image_offer" {
  description = "VM image offer"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "vm_image_sku" {
  description = "VM image SKU"
  type        = string
  default     = "22_04-lts-gen2"
}

variable "vm_image_version" {
  description = "VM image version"
  type        = string
  default     = "latest"
}

variable "ssh_public_key" {
  description = "SSH public key for jumpbox (base64 encoded)"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDR3b7fZ5N7VvN8..." # Replace with your key
  sensitive   = true
}

# Windows VM Configuration
variable "windows_vm_size" {
  description = "VM size for Windows jumpbox"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "windows_admin_password" {
  description = "Admin password for Windows jumpbox VM"
  type        = string
  sensitive   = true
}

variable "windows_vm_image_publisher" {
  description = "Windows VM image publisher"
  type        = string
  default     = "MicrosoftWindowsServer"
}

variable "windows_vm_image_offer" {
  description = "Windows VM image offer"
  type        = string
  default     = "WindowsServer"
}

variable "windows_vm_image_sku" {
  description = "Windows VM image SKU"
  type        = string
  default     = "2022-datacenter-azure-edition"
}

variable "windows_vm_image_version" {
  description = "Windows VM image version"
  type        = string
  default     = "latest"
}

# ACA Configuration
variable "aca_workload_profile" {
  description = "Workload profile for Container Apps (Consumption, Dedicated)"
  type        = string
  default     = "Consumption"
}

# Container App Configuration
variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "container_cpu" {
  description = "CPU allocation for container (e.g., 0.5, 1.0)"
  type        = string
  default     = "0.5"
}

variable "container_memory" {
  description = "Memory allocation for container (e.g., 1Gi, 2Gi)"
  type        = string
  default     = "1Gi"
}

variable "min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 5
}

# Log Analytics Configuration
variable "log_analytics_retention_days" {
  description = "Log Analytics workspace retention in days"
  type        = number
  default     = 30
}

# Application Insights Configuration
variable "enable_application_insights" {
  description = "Enable Application Insights for monitoring"
  type        = bool
  default     = true
}

variable "application_insights_retention_days" {
  description = "Application Insights retention in days (30-730)"
  type        = number
  default     = 90
}

variable "application_insights_sampling_percentage" {
  description = "Percentage of requests to sample (0-100). Set to 100 for full fidelity, lower for cost optimization"
  type        = number
  default     = 100
}

# Tags
variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    environment = "dev"
    project     = "azlz"
    created_by  = "terraform"
  }
}
