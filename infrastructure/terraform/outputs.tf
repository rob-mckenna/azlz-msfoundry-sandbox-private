output "resource_group_id" {
  description = "The ID of the created resource group"
  value       = azurerm_resource_group.main.id
}

output "resource_group_name" {
  description = "The name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "acr_id" {
  description = "The ID of the container registry"
  value       = azurerm_container_registry.main.id
}

output "acr_name" {
  description = "The name of the container registry"
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "The login server URL for the container registry"
  value       = azurerm_container_registry.main.login_server
}

output "aca_environment_id" {
  description = "The ID of the container apps environment"
  value       = azurerm_container_app_environment.main.id
}

output "aca_environment_name" {
  description = "The name of the container apps environment"
  value       = azurerm_container_app_environment.main.name
}

output "container_app_id" {
  description = "The ID of the container app"
  value       = azurerm_container_app.main.id
}

output "container_app_name" {
  description = "The name of the container app"
  value       = azurerm_container_app.main.name
}

output "container_app_fqdn" {
  description = "The fully qualified domain name (FQDN) of the container app"
  value       = azurerm_container_app.main.ingress[0].fqdn
}

output "container_app_url" {
  description = "The URL of the container app"
  value       = "https://${azurerm_container_app.main.ingress[0].fqdn}"
}

output "jumpbox_vm_id" {
  description = "The ID of the jumpbox VM"
  value       = azurerm_linux_virtual_machine.jumpbox.id
}

output "jumpbox_vm_name" {
  description = "The name of the jumpbox VM"
  value       = azurerm_linux_virtual_machine.jumpbox.name
}

output "jumpbox_private_ip" {
  description = "The private IP address of the jumpbox VM"
  value       = azurerm_network_interface.jumpbox.private_ip_address
}

output "jumpbox_public_ip" {
  description = "The public IP address of the jumpbox VM (for reference only, use Bastion for access)"
  value       = azurerm_public_ip.jumpbox.ip_address
}

output "jumpbox_windows_vm_id" {
  description = "The ID of the Windows jumpbox VM"
  value       = azurerm_windows_virtual_machine.jumpbox.id
}

output "jumpbox_windows_vm_name" {
  description = "The name of the Windows jumpbox VM"
  value       = azurerm_windows_virtual_machine.jumpbox.name
}

output "jumpbox_windows_private_ip" {
  description = "The private IP address of the Windows jumpbox VM"
  value       = azurerm_network_interface.jumpbox_windows.private_ip_address
}

output "jumpbox_windows_public_ip" {
  description = "The public IP address of the Windows jumpbox VM (for reference only, use Bastion for access)"
  value       = azurerm_public_ip.jumpbox_windows.ip_address
}

output "bastion_id" {
  description = "The ID of the bastion host"
  value       = azurerm_bastion_host.main.id
}

output "bastion_name" {
  description = "The name of the bastion host"
  value       = azurerm_bastion_host.main.name
}

output "bastion_public_ip" {
  description = "The public IP address of the bastion host"
  value       = azurerm_public_ip.bastion.ip_address
}

output "log_analytics_workspace_id" {
  description = "The ID of the log analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "The name of the log analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "application_insights_id" {
  description = "The ID of the Application Insights resource"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].id : null
}

output "application_insights_name" {
  description = "The name of the Application Insights resource"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].name : null
}

output "application_insights_instrumentation_key" {
  description = "The instrumentation key for Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].instrumentation_key : null
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "The connection string for Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].connection_string : null
  sensitive   = true
}

output "user_assigned_identity_id" {
  description = "The ID of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.aca.id
}

output "user_assigned_identity_name" {
  description = "The name of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.aca.name
}

output "user_assigned_identity_principal_id" {
  description = "The principal ID of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.aca.principal_id
}

output "acr_subnet_id" {
  description = "The ID of the ACR subnet"
  value       = azurerm_subnet.acr.id
}

output "aca_subnet_id" {
  description = "The ID of the Container Apps subnet"
  value       = azurerm_subnet.aca.id
}

output "jumpbox_subnet_id" {
  description = "The ID of the jumpbox subnet"
  value       = azurerm_subnet.jumpbox.id
}

output "bastion_subnet_id" {
  description = "The ID of the bastion subnet"
  value       = azurerm_subnet.bastion.id
}

output "acr_private_endpoint_id" {
  description = "The ID of the ACR private endpoint"
  value       = var.enable_acr_private_endpoint ? azurerm_private_endpoint.acr[0].id : null
}

output "acr_private_dns_zone_id" {
  description = "The ID of the ACR private DNS zone"
  value       = var.enable_acr_private_endpoint ? azurerm_private_dns_zone.acr[0].id : null
}

output "acr_private_dns_zone_name" {
  description = "The name of the ACR private DNS zone"
  value       = var.enable_acr_private_endpoint ? azurerm_private_dns_zone.acr[0].name : null
}

output "apim_id" {
  description = "The ID of the API Management service"
  value       = azurerm_api_management.main.id
}

output "apim_name" {
  description = "The name of the API Management service"
  value       = azurerm_api_management.main.name
}

output "apim_gateway_url" {
  description = "The gateway URL of the API Management service"
  value       = azurerm_api_management.main.gateway_url
}

output "apim_portal_url" {
  description = "The developer portal URL of the API Management service"
  value       = azurerm_api_management.main.developer_portal_url
}

output "apim_private_endpoint_id" {
  description = "The ID of the APIM private endpoint"
  value       = var.enable_apim_private_endpoint ? azurerm_private_endpoint.apim[0].id : null
}

output "apim_private_dns_zone_id" {
  description = "The ID of the APIM private DNS zone"
  value       = var.enable_apim_private_endpoint ? azurerm_private_dns_zone.apim[0].id : null
}

output "apim_logger_id" {
  description = "The ID of the APIM Application Insights logger"
  value       = var.enable_apim_logging && var.enable_application_insights ? azurerm_api_management_logger.app_insights[0].id : null
}

output "apim_diagnostic_id" {
  description = "The ID of the APIM Application Insights diagnostic"
  value       = var.enable_apim_logging && var.enable_application_insights ? azurerm_api_management_diagnostic.app_insights[0].id : null
}

output "aca_private_dns_zone_id" {
  description = "The ID of the Container Apps private DNS zone"
  value       = var.enable_aca_private_endpoint ? azurerm_private_dns_zone.aca[0].id : null
}

output "aca_private_dns_zone_name" {
  description = "The name of the Container Apps private DNS zone"
  value       = var.enable_aca_private_endpoint ? azurerm_private_dns_zone.aca[0].name : null
}

output "apim_subnet_id" {
  description = "The ID of the APIM subnet"
  value       = azurerm_subnet.apim.id
}
output "cicd_subnet_id" {
  description = "The ID of the CI/CD subnet"
  value       = var.enable_cicd_runner ? azurerm_subnet.cicd[0].id : null
}

output "cicd_environment_id" {
  description = "The ID of the CI/CD Container Apps environment"
  value       = var.enable_cicd_runner ? azurerm_container_app_environment.cicd[0].id : null
}

output "cicd_environment_name" {
  description = "The name of the CI/CD Container Apps environment"
  value       = var.enable_cicd_runner ? azurerm_container_app_environment.cicd[0].name : null
}

output "github_runner_id" {
  description = "The ID of the GitHub Actions runner Container App Job"
  value       = var.enable_cicd_runner && var.github_runner_registration_token != "" ? azurerm_container_app_job.github_runner[0].id : null
  sensitive   = true
}

output "github_runner_name" {
  description = "The name of the GitHub Actions runner"
  value       = local.github_runner_name
}

output "cicd_identity_id" {
  description = "The ID of the CI/CD user-assigned managed identity"
  value       = var.enable_cicd_runner ? azurerm_user_assigned_identity.cicd[0].id : null
}

output "cicd_identity_principal_id" {
  description = "The principal ID of the CI/CD user-assigned managed identity"
  value       = var.enable_cicd_runner ? azurerm_user_assigned_identity.cicd[0].principal_id : null
}