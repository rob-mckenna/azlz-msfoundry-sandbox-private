locals {
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : "${var.project_name}-rg"
  unique_suffix       = substr(md5("${data.azurerm_client_config.current.subscription_id}${var.location}"), 0, 4)

  vnet_name           = "${var.project_name}-vnet-${var.environment}"
  acr_name            = "${var.project_name}acr${local.unique_suffix}"
  acr_subnet_name     = "${var.project_name}-acr-subnet"
  aca_subnet_name     = "${var.project_name}-aca-subnet"
  jumpbox_subnet_name = "${var.project_name}-jumpbox-subnet"
  bastion_subnet_name = "AzureBastionSubnet"
  apim_subnet_name    = "${var.project_name}-apim-subnet"
  cicd_subnet_name    = "${var.project_name}-cicd-subnet"

  nsg_acr_name     = "${var.project_name}-acr-nsg"
  nsg_aca_name     = "${var.project_name}-aca-nsg"
  nsg_jumpbox_name = "${var.project_name}-jumpbox-nsg"
  nsg_bastion_name = "${var.project_name}-bastion-nsg"
  nsg_apim_name    = "${var.project_name}-apim-nsg"
  nsg_cicd_name    = "${var.project_name}-cicd-nsg"

  jumpbox_nic_name = "${var.project_name}-jumpbox-nic"
  jumpbox_vm_name  = "${var.project_name}-jumpbox-vm"
  jumpbox_pip_name = "${var.project_name}-jumpbox-pip"
  
  jumpbox_windows_nic_name = "${var.project_name}-jumpbox-win-nic"
  jumpbox_windows_vm_name  = "${var.project_name}-jumpbox-win-vm"
  jumpbox_windows_pip_name = "${var.project_name}-jumpbox-win-pip"
  
  bastion_name     = "${var.project_name}-bastion"
  bastion_pip_name = "${var.project_name}-bastion-pip"

  aca_environment_name      = "${var.project_name}-aca-env-${var.environment}"
  cicd_environment_name     = "${var.project_name}-cicd-env-${var.environment}"
  container_app_name        = "${var.project_name}-app"
  github_runner_name        = "${var.project_name}-runner"
  apim_name                 = "${var.project_name}-apim-${local.unique_suffix}"

  log_analytics_workspace_name = "${var.project_name}-law-${var.environment}"
  application_insights_name    = "${var.project_name}-ai-${var.environment}"
  user_assigned_identity_name  = "${var.project_name}-uami"
  cicd_identity_name           = "${var.project_name}-cicd-uami"

  common_tags = merge(
    var.tags,
    {
      created_date = timestamp()
      location     = var.location
    }
  )
}

# =====================
# RESOURCE GROUP
# =====================

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# =====================
# NETWORKING - NSGs
# =====================

resource "azurerm_network_security_group" "acr" {
  name                = local.nsg_acr_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  security_rule {
    name                       = "AllowFromACASubnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.aca_subnet_address_space
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "aca" {
  name                = local.nsg_aca_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  security_rule {
    name                       = "AllowHttps"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHttp"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "jumpbox" {
  name                = local.nsg_jumpbox_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  security_rule {
    name                       = "AllowBastionInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.bastion_subnet_address_space
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "bastion" {
  name                = local.nsg_bastion_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  security_rule {
    name                       = "AllowHttpsInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowGatewayManagerInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowLoadBalancerInbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowBastionHostCommunication"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowSshRdpOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowAzureCloudOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }
}

resource "azurerm_network_security_group" "apim" {
  name                = local.nsg_apim_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  security_rule {
    name                       = "AllowClientCommunication"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowManagementEndpoint"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3443"
    source_address_prefix      = "ApiManagement"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowAzureLoadBalancer"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6390"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowStorageOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Storage"
  }

  security_rule {
    name                       = "AllowSqlOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Sql"
  }

  security_rule {
    name                       = "AllowKeyVaultOutbound"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureKeyVault"
  }
}

resource "azurerm_network_security_group" "cicd" {
  count = var.enable_cicd_runner ? 1 : 0

  name                = local.nsg_cicd_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  security_rule {
    name                       = "AllowOutboundInternet"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "AllowInternalCommunication"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }
}

# =====================
# NETWORKING - VNet & Subnets
# =====================

resource "azurerm_virtual_network" "main" {
  name                = local.vnet_name
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_subnet" "acr" {
  name                 = local.acr_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.acr_subnet_address_space]

  service_endpoints = [
    "Microsoft.ContainerRegistry",
    "Microsoft.KeyVault"
  ]
}

resource "azurerm_subnet_network_security_group_association" "acr" {
  subnet_id                 = azurerm_subnet.acr.id
  network_security_group_id = azurerm_network_security_group.acr.id
}

resource "azurerm_subnet" "aca" {
  name                 = local.aca_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aca_subnet_address_space]

  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.App/environments"
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "aca" {
  subnet_id                 = azurerm_subnet.aca.id
  network_security_group_id = azurerm_network_security_group.aca.id
}

resource "azurerm_subnet" "jumpbox" {
  name                 = local.jumpbox_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.jumpbox_subnet_address_space]
}

resource "azurerm_subnet_network_security_group_association" "jumpbox" {
  subnet_id                 = azurerm_subnet.jumpbox.id
  network_security_group_id = azurerm_network_security_group.jumpbox.id
}

resource "azurerm_subnet" "bastion" {
  name                 = local.bastion_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.bastion_subnet_address_space]
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

resource "azurerm_subnet" "apim" {
  name                 = local.apim_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.apim_subnet_address_space]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.Sql",
    "Microsoft.KeyVault"
  ]
}

resource "azurerm_subnet_network_security_group_association" "apim" {
  subnet_id                 = azurerm_subnet.apim.id
  network_security_group_id = azurerm_network_security_group.apim.id
}

resource "azurerm_subnet" "cicd" {
  count = var.enable_cicd_runner ? 1 : 0

  name                 = local.cicd_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.cicd_subnet_address_space]

  service_endpoints = [
    "Microsoft.ContainerRegistry",
    "Microsoft.Storage"
  ]
}

resource "azurerm_subnet_network_security_group_association" "cicd" {
  count = var.enable_cicd_runner ? 1 : 0

  subnet_id                 = azurerm_subnet.cicd[0].id
  network_security_group_id = azurerm_network_security_group.cicd[0].id
}

# =====================
# CONTAINER REGISTRY
# =====================

resource "azurerm_container_registry" "main" {
  name                = local.acr_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.acr_sku

  admin_enabled                 = var.acr_admin_enabled
  public_network_access_enabled = var.enable_acr_private_endpoint ? false : true

  network_rule_bypass_option = "AzureServices"

  quarantine_policy_enabled = false

  retention_policy {
    days    = 30
    enabled = true
  }

  trust_policy {
    enabled = false
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# =====================
# PRIVATE DNS ZONE FOR ACR
# =====================

resource "azurerm_private_dns_zone" "acr" {
  count = var.enable_acr_private_endpoint ? 1 : 0

  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  count = var.enable_acr_private_endpoint ? 1 : 0

  name                  = "${azurerm_virtual_network.main.name}-acr-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.acr[0].name
  virtual_network_id    = azurerm_virtual_network.main.id

  tags = local.common_tags
}

# =====================
# PRIVATE ENDPOINT FOR ACR
# =====================

resource "azurerm_private_endpoint" "acr" {
  count = var.enable_acr_private_endpoint ? 1 : 0

  name                = "${local.acr_name}-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.acr.id

  private_service_connection {
    name                           = "${local.acr_name}-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr[0].id]
  }

  tags = local.common_tags

  depends_on = [
    azurerm_private_dns_zone.acr
  ]
}

# =====================
# LOG ANALYTICS
# =====================

resource "azurerm_log_analytics_workspace" "main" {
  name                = local.log_analytics_workspace_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days

  tags = local.common_tags
}

# =====================
# APPLICATION INSIGHTS
# =====================

resource "azurerm_application_insights" "main" {
  count = var.enable_application_insights ? 1 : 0

  name                = "${var.project_name}-ai-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id
  retention_in_days   = var.application_insights_retention_days

  tags = local.common_tags
}

# =====================
# API MANAGEMENT
# =====================

resource "azurerm_api_management" "main" {
  name                = local.apim_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = "${var.apim_sku}_${var.apim_capacity}"

  public_network_access_enabled = var.enable_apim_private_endpoint ? false : true

  virtual_network_type = var.enable_apim_private_endpoint ? "Internal" : "None"

  dynamic "virtual_network_configuration" {
    for_each = var.enable_apim_private_endpoint ? [1] : []
    content {
      subnet_id = azurerm_subnet.apim.id
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags

  depends_on = [
    azurerm_subnet.apim
  ]
}

# =====================
# APIM APPLICATION INSIGHTS LOGGER
# =====================

resource "azurerm_api_management_logger" "app_insights" {
  count = var.enable_apim_logging && var.enable_application_insights ? 1 : 0

  name                = "${local.apim_name}-logger"
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  resource_id         = azurerm_application_insights.main[0].id

  application_insights {
    instrumentation_key = azurerm_application_insights.main[0].instrumentation_key
  }

  depends_on = [
    azurerm_application_insights.main
  ]
}

# =====================
# APIM DIAGNOSTIC SETTINGS
# =====================

resource "azurerm_api_management_diagnostic" "app_insights" {
  count = var.enable_apim_logging && var.enable_application_insights ? 1 : 0

  identifier              = "applicationinsights"
  resource_group_name     = azurerm_resource_group.main.name
  api_management_name     = azurerm_api_management.main.name
  api_management_logger_id = azurerm_api_management_logger.app_insights[0].id

  sampling_percentage       = 100
  always_log_errors         = true
  log_client_ip             = true
  verbosity                 = "verbose"
  http_correlation_protocol = "W3C"

  frontend_request {
    body_bytes = 8192
  }

  frontend_response {
    body_bytes = 8192
  }

  backend_request {
    body_bytes = 8192
  }

  backend_response {
    body_bytes = 8192
  }

  depends_on = [
    azurerm_api_management_logger.app_insights
  ]
}

# =====================
# PRIVATE DNS ZONE FOR APIM
# =====================

resource "azurerm_private_dns_zone" "apim" {
  count = var.enable_apim_private_endpoint ? 1 : 0

  name                = "azure-api.net"
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "apim" {
  count = var.enable_apim_private_endpoint ? 1 : 0

  name                  = "${azurerm_virtual_network.main.name}-apim-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.apim[0].name
  virtual_network_id    = azurerm_virtual_network.main.id

  tags = local.common_tags
}

# =====================
# PRIVATE ENDPOINT FOR APIM
# =====================

resource "azurerm_private_endpoint" "apim" {
  count = var.enable_apim_private_endpoint ? 1 : 0

  name                = "${local.apim_name}-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.apim.id

  private_service_connection {
    name                           = "${local.apim_name}-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_api_management.main.id
    subresource_names              = ["Gateway"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.apim[0].id]
  }

  tags = local.common_tags

  depends_on = [
    azurerm_private_dns_zone.apim,
    azurerm_api_management.main
  ]
}

# =====================
# PRIVATE DNS ZONE FOR CONTAINER APPS
# =====================

resource "azurerm_private_dns_zone" "aca" {
  count = var.enable_aca_private_endpoint ? 1 : 0

  name                = azurerm_container_app_environment.main.default_domain
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags

  depends_on = [
    azurerm_container_app_environment.main
  ]
}

resource "azurerm_private_dns_zone_virtual_network_link" "aca" {
  count = var.enable_aca_private_endpoint ? 1 : 0

  name                  = "${azurerm_virtual_network.main.name}-aca-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.aca[0].name
  virtual_network_id    = azurerm_virtual_network.main.id

  tags = local.common_tags
}

# =====================
# MANAGED IDENTITY
# =====================

resource "azurerm_user_assigned_identity" "aca" {
  name                = local.user_assigned_identity_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

resource "azurerm_role_assignment" "aca_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aca.principal_id
}

# =====================
# CONTAINER APPS ENVIRONMENT
# =====================

resource "azurerm_container_app_environment" "main" {
  name                           = local.aca_environment_name
  location                       = azurerm_resource_group.main.location
  resource_group_name            = azurerm_resource_group.main.name
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.main.id
  infrastructure_subnet_id       = azurerm_subnet.aca.id
  internal_load_balancer_enabled = var.enable_aca_private_endpoint

  tags = local.common_tags

  depends_on = [
    azurerm_subnet.aca,
    azurerm_log_analytics_workspace.main
  ]
}

# =====================
# CI/CD CONTAINER APPS ENVIRONMENT
# =====================

resource "azurerm_container_app_environment" "cicd" {
  count = var.enable_cicd_runner ? 1 : 0

  name                           = local.cicd_environment_name
  location                       = azurerm_resource_group.main.location
  resource_group_name            = azurerm_resource_group.main.name
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.main.id
  infrastructure_subnet_id       = azurerm_subnet.cicd[0].id
  internal_load_balancer_enabled = false

  tags = merge(local.common_tags, { purpose = "cicd" })

  depends_on = [
    azurerm_subnet.cicd,
    azurerm_log_analytics_workspace.main
  ]
}

# =====================
# CI/CD MANAGED IDENTITY
# =====================

resource "azurerm_user_assigned_identity" "cicd" {
  count = var.enable_cicd_runner ? 1 : 0

  name                = local.cicd_identity_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

resource "azurerm_role_assignment" "cicd_acr_pull" {
  count = var.enable_cicd_runner ? 1 : 0

  scope              = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id       = azurerm_user_assigned_identity.cicd[0].principal_id
}

# =====================
# CI/CD CONTAINER APP JOB
# =====================

resource "azurerm_container_app_job" "github_runner" {
  count = var.enable_cicd_runner && var.github_runner_registration_token != "" ? 1 : 0

  name                         = local.github_runner_name
  container_app_environment_id = azurerm_container_app_environment.cicd[0].id
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location

  replica_timeout_in_seconds = 3600

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.cicd[0].id]
  }

  template {
    container {
      name   = "github-runner"
      image  = var.runner_container_image
      memory = "2Gi"
      cpu    = 1

      env {
        name  = "GITHUB_TOKEN"
        value = var.github_runner_registration_token
      }

      env {
        name  = "GITHUB_REPOSITORY"
        value = var.github_runner_url
      }

      env {
        name  = "RUNNER_NAME"
        value = local.github_runner_name
      }

      env {
        name  = "RUNNER_WORK_DIRECTORY"
        value = "/_work"
      }

      dynamic "env" {
        for_each = var.enable_application_insights ? [1] : []
        content {
          name  = "APPLICATIONINSIGHTS_CONNECTION_STRING"
          value = azurerm_application_insights.main[0].connection_string
        }
      }
    }
  }

  manual_trigger_config {
    parallelism              = 1
    replica_completion_count = 1
  }

  tags = merge(local.common_tags, { purpose = "github-runner" })

  depends_on = [
    azurerm_container_app_environment.cicd,
    azurerm_user_assigned_identity.cicd,
    azurerm_role_assignment.cicd_acr_pull
  ]
}

# =====================
# CONTAINER APP
# =====================

resource "azurerm_container_app" "main" {
  name                         = local.container_app_name
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca.id]
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = var.enable_container_app_external
    target_port                = var.container_port
    transport                  = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  registry {
    identity             = azurerm_user_assigned_identity.aca.id
    password_secret_name = "acr-password"
    server               = azurerm_container_registry.main.login_server
    username             = azurerm_container_registry.main.name
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.main.admin_password
  }

  template {
    revision_suffix = "init"

    container {
      name   = local.container_app_name
      image  = "${azurerm_container_registry.main.login_server}/${local.container_app_name}:latest"
      cpu    = var.container_cpu
      memory = var.container_memory

      env {
        name  = "ASPNETCORE_URLS"
        value = "http://+:${var.container_port}"
      }

      dynamic "env" {
        for_each = var.enable_application_insights ? [1] : []
        content {
          name  = "APPLICATIONINSIGHTS_CONNECTION_STRING"
          value = azurerm_application_insights.main[0].connection_string
        }
      }

      liveness_probe {
        transport = "HTTP"
        port      = var.container_port
        path      = "/health"
      }

      readiness_probe {
        transport = "HTTP"
        port      = var.container_port
        path      = "/ready"
      }
    }

    max_replicas = var.max_replicas
    min_replicas = var.min_replicas

    custom_scale_rule {
      custom_rule_type = "http"
      metadata = {
        "concurrentRequests" = "100"
      }
      name = "http-requests"
    }
  }

  tags = local.common_tags

  depends_on = [
    azurerm_role_assignment.aca_acr_pull,
    azurerm_container_registry.main
  ]
}

# =====================
# JUMPBOX VM
# =====================

resource "azurerm_public_ip" "jumpbox" {
  name                    = local.jumpbox_pip_name
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  allocation_method       = "Static"
  sku                     = "Standard"
  idle_timeout_in_minutes = 4

  tags = local.common_tags
}

resource "azurerm_network_interface" "jumpbox" {
  name                = local.jumpbox_nic_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.jumpbox.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox.id
  }

  tags = local.common_tags
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                = local.jumpbox_vm_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.vm_size

  admin_username = var.admin_username

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  network_interface_ids = [
    azurerm_network_interface.jumpbox.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = var.vm_image_publisher
    offer     = var.vm_image_offer
    sku       = var.vm_image_sku
    version   = var.vm_image_version
  }

  tags = local.common_tags
}

# =====================
# WINDOWS JUMPBOX VM
# =====================

resource "azurerm_public_ip" "jumpbox_windows" {
  name                    = local.jumpbox_windows_pip_name
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  allocation_method       = "Static"
  sku                     = "Standard"
  idle_timeout_in_minutes = 4

  tags = local.common_tags
}

resource "azurerm_network_interface" "jumpbox_windows" {
  name                = local.jumpbox_windows_nic_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.jumpbox.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox_windows.id
  }

  tags = local.common_tags
}

resource "azurerm_windows_virtual_machine" "jumpbox" {
  name                = local.jumpbox_windows_vm_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.windows_vm_size

  admin_username = var.admin_username
  admin_password = var.windows_admin_password

  network_interface_ids = [
    azurerm_network_interface.jumpbox_windows.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = var.windows_vm_image_publisher
    offer     = var.windows_vm_image_offer
    sku       = var.windows_vm_image_sku
    version   = var.windows_vm_image_version
  }

  tags = local.common_tags
}

# =====================
# AZURE BASTION
# =====================

resource "azurerm_public_ip" "bastion" {
  name                = local.bastion_pip_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

resource "azurerm_bastion_host" "main" {
  name                = local.bastion_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Basic"

  ip_configuration {
    name                 = "IpConf"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = local.common_tags

  depends_on = [
    azurerm_subnet.bastion
  ]
}
