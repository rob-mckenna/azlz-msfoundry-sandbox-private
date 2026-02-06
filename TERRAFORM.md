# Terraform Deployment Guide

## Overview

This Azure Landing Zone uses **Terraform** (v1.5+) with the Azure Provider (v3.80+) to manage all infrastructure components via Infrastructure as Code (IaC).

## Terraform Project Structure

```
infrastructure/terraform/
├── provider.tf              # Azure provider configuration
├── versions.tf              # Required versions
├── main.tf                  # Main resource definitions
├── variables.tf             # Variable declarations
├── outputs.tf               # Output values
├── terraform.tfvars         # Variable values (environment-specific)
├── terraform.tfstate        # State file (local)
├── .terraform/              # Provider plugins (generated)
└── .terraform.lock.hcl      # Dependency lock file (generated)
```

## Key Terraform Files Explained

### provider.tf
Configures the Azure provider and authentication:
- Uses Azure CLI credentials automatically
- Defines feature flags for resources like VMs and Key Vault
- Disables provider registration requirement (allows delegated access)

### main.tf
Contains all resource definitions:
- **Locals**: Derived values and naming conventions
- **Resource Group**: Foundation for all resources
- **Networking**: VNet, subnets, NSGs with proper delegation
- **ACR**: Container registry with managed identity integration
- **Log Analytics**: Monitoring and logging
- **ACA**: Container Apps environment and app
- **VM & Bastion**: Administrative access infrastructure

### variables.tf
Declares all input variables with:
- Default values (can be overridden)
- Type constraints (string, number, bool, object, etc.)
- Descriptions for clarity
- Sensitive flag for SSH keys

### outputs.tf
Exports important values for use outside Terraform:
- Resource IDs and names
- Access endpoints (Container App URL, etc.)
- Managed identity details
- Subnet IDs

### terraform.tfvars
Environment-specific values:
```hcl
location                = "eastus"
environment             = "dev"
project_name            = "azlz"
acr_sku                 = "Premium"
apim_sku                = "StandardV2"
ssh_public_key          = "ssh-rsa AAAA..."
enable_acr_private_endpoint  = true
enable_apim_private_endpoint = true
enable_aca_private_endpoint  = true
```

## Workflow

### 1. Initialize Terraform
```bash
cd infrastructure/terraform
terraform init
```

This:
- Downloads Azure provider plugin
- Creates `.terraform/` directory
- Generates `.terraform.lock.hcl` (dependency lock)
- Initializes local state

### 2. Validate Configuration
```bash
terraform validate
```

Checks syntax and structure without connecting to Azure.

### 3. Plan
```bash
terraform plan -out=tfplan
```

Shows what changes will be applied:
- Resources to create/modify/destroy
- No actual changes to Azure
- Safe to review before applying

### 4. Apply
```bash
terraform apply tfplan
```

Creates/updates resources in Azure based on the plan.

### 5. Outputs
```bash
terraform output
terraform output -raw container_app_url
```

Retrieves output values for use in scripts or manual processes.

## State Management

### What is Terraform State?
- JSON file mapping configuration to real resources
- **Critical**: Contains resource IDs and configuration
- **Sensitive**: May contain secrets (use remote state in production)
- **Default Location**: Local file `terraform.tfstate`

### Backup State
```bash
# Automatic backup created as terraform.tfstate.backup
# Manual backup:
cp terraform.tfstate terraform.tfstate.backup
```

### Remote State (Production)
For team environments, use Azure Storage:

```hcl
# infrastructure/terraform/backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstate"
    container_name       = "tfstate"
    key                  = "landing-zone.tfstate"
  }
}
```

Migrate existing state:
```bash
cd infrastructure/terraform
terraform init -migrate-state
```

## Variables and Overrides

### Using Different Values

#### Method 1: terraform.tfvars (Default)
```bash
terraform apply  # Uses terraform.tfvars automatically
```

#### Method 2: CLI Arguments
```bash
terraform apply -var="location=westus" -var="vm_size=Standard_B4ms"
```

#### Method 3: Environment Variables
```bash
export TF_VAR_location=westus
export TF_VAR_environment=staging
terraform apply
```

#### Method 4: Additional tfvars Files
```bash
# For staging environment
terraform apply -var-file="staging.tfvars"

# For production environment
terraform apply -var-file="production.tfvars"
```

### Environment-Specific Files

Create separate tfvars for each environment:

**dev.tfvars**
```hcl
environment     = "dev"
location        = "eastus"
vm_size         = "Standard_B2s"
acr_sku         = "Standard"  # Cost optimization for dev
apim_sku        = "Developer" # Cost optimization for dev
max_replicas    = 3
enable_acr_private_endpoint  = false  # Save costs in dev
enable_apim_private_endpoint = false
```

**production.tfvars**
```hcl
environment     = "prod"
location        = "eastus"
vm_size         = "Standard_D2s_v3"
acr_sku         = "Premium"  # Required for private endpoints
apim_sku        = "StandardV2"
max_replicas    = 10
enable_acr_private_endpoint  = true
enable_apim_private_endpoint = true
enable_aca_private_endpoint  = true
```

Deploy to different environments:
```bash
terraform apply -var-file="dev.tfvars"
# or
terraform apply -var-file="production.tfvars"
```

### GitHub Actions Self-Hosted Runner Configuration

To enable the optional CI/CD runner (GitHub Actions), add to your terraform.tfvars:

```hcl
# Enable self-hosted runner
enable_cicd_runner = true

# GitHub runner registration token (from repo → Settings → Actions → Runners)
github_runner_registration_token = "AAAA..."

# GitHub repository URL for runner registration
github_runner_url = "https://github.com/your-org/your-repo"

# Container image for the runner (must have GitHub Actions runner pre-installed)
runner_container_image = "ghcr.io/myoats/actions-runner:latest"
```

The CI/CD runner will:
- Deploy to its own Container Apps environment
- Run in a dedicated subnet (10.0.6.0/24)
- Have ACR pull permission via managed identity
- Register automatically with GitHub
- Run CI/CD jobs inside the VNet

See README.md Step 6 for complete setup instructions.

## Common Terraform Commands

### Plan and Apply
```bash
# Plan with output file
terraform plan -out=tfplan

# Apply saved plan
terraform apply tfplan

# Apply with auto-approval (use cautiously)
terraform apply -auto-approve
```

### State Operations
```bash
# List all resources
terraform state list

# Show specific resource details
terraform state show azurerm_container_app.main

# Remove resource from state (doesn't delete from Azure)
terraform state rm azurerm_resource_group.main

# Replace resource
terraform state replace-provider hashicorp/azurerm azure-provider/azurerm
```

### Inspection
```bash
# Show plan without applying
terraform plan

# Show current state
terraform show

# Show specific output
terraform output acr_login_server

# Validate syntax
terraform validate

# Format code
terraform fmt

# Show providers
terraform providers
```

### Destroy
```bash
# Plan destruction
terraform plan -destroy

# Destroy all resources
terraform destroy

# Destroy specific resource
terraform destroy -target=azurerm_container_app.main
```

### Workspaces (Multiple Environments)
```bash
# List workspaces
terraform workspace list

# Create workspace
terraform workspace new staging

# Switch workspace
terraform workspace select staging

# Delete workspace
terraform workspace delete staging
```

## Locals and Dynamic Values

The Terraform configuration uses `locals` for derived values:

```hcl
locals {
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : "${var.project_name}-rg"
  unique_suffix       = substr(md5("${data.azurerm_client_config.current.subscription_id}${var.location}"), 0, 4)
  acr_name            = "${var.project_name}acr${local.unique_suffix}"
  common_tags = merge(
    var.tags,
    {
      created_date = timestamp()
      location     = var.location
    }
  )
}
```

This ensures:
- Consistent naming across resources
- Unique names per subscription/location
- Automated tagging with creation date

## Managing Secrets

### SSH Public Key
1. Generate locally:
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/azlz-jumpbox -N ""
   ```

2. Add to terraform.tfvars:
   ```hcl
   ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADA..."
   ```

### Azure Credentials
Terraform uses Azure CLI credentials:
```bash
az login
az account set --subscription "SUBSCRIPTION_ID"
```

### ACR Password (Managed)
Terraform reads ACR admin password automatically:
```hcl
secret {
  name  = "acr-password"
  value = azurerm_container_registry.main.admin_password
}
```

### Future: Azure Key Vault Integration
For production, store secrets in Key Vault:
```hcl
resource "azurerm_key_vault_secret" "ssh_key" {
  name         = "jumpbox-ssh-key"
  value        = var.ssh_public_key
  key_vault_id = azurerm_key_vault.main.id
}
```

## Terraform Style and Best Practices

Following [Terraform Style Conventions](https://developer.hashicorp.com/terraform/language/style):

### Naming
- **Files**: Snake_case (e.g., `main.tf`, `variables.tf`)
- **Resources**: Snake_case (e.g., `azurerm_virtual_network`)
- **Variables**: Snake_case (e.g., `vm_size`)
- **Locals**: Snake_case (e.g., `common_tags`)

### Organization
```hcl
# 1. Terraform block
terraform {
  required_version = ">= 1.5"
}

# 2. Provider block
provider "azurerm" {
  features {}
}

# 3. Data sources
data "azurerm_client_config" "current" {}

# 4. Locals
locals {
  naming = ...
}

# 5. Resources (logical grouping)
# 6. Outputs
```

### Formatting
```bash
# Auto-format all files
terraform fmt -recursive

# Check formatting
terraform fmt -check
```

## Troubleshooting

### Common Issues

#### 1. "Provider Not Initialized"
```bash
terraform init
```

#### 2. "Conflicting Resource Names"
Check the unique_suffix generation in locals. Names should be unique per subscription/location.

#### 3. "Authentication Failed"
```bash
az login
az account show  # Verify correct subscription
```

#### 4. "State Lock Timeout"
Another Terraform process is running:
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

#### 5. "Resource Already Exists"
```bash
# Import existing resource into state
terraform import azurerm_resource_group.main /subscriptions/SUB_ID/resourceGroups/RG_NAME
```

### Debugging

Enable debug logging:
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
terraform apply
```

View details:
```bash
tail -f terraform.log
```

## Updating Infrastructure

### Adding Resources
1. Edit `main.tf`
2. Add resource block with descriptive name
3. Reference existing resources using `azurerm_*.id` or similar
4. Run `terraform plan` to validate
5. Run `terraform apply` to deploy

### Modifying Resources
1. Edit existing resource block
2. Run `terraform plan` to see changes
3. Review carefully (some changes may recreate resources)
4. Run `terraform apply` to apply changes

### Example: Scaling Container App
```hcl
# In main.tf or via variable
max_replicas = 10  # Change from 5

# Or via CLI
terraform apply -var="max_replicas=10"
```

### Example: Changing VM Size
```hcl
# In terraform.tfvars
vm_size = "Standard_D2s_v3"  # Change from B2s

terraform apply
```

## Integration with Scripts

### Export Values for Scripts
```bash
#!/bin/bash
cd infrastructure/terraform

ACR_NAME=$(terraform output -raw acr_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
CONTAINER_APP_URL=$(terraform output -raw container_app_url)

# Use in script
docker build -t ${ACR_NAME}.azurecr.io/app:latest .
docker push ${ACR_NAME}.azurecr.io/app:latest
```

### JSON Output
```bash
# Get all outputs as JSON
terraform output -json > outputs.json

# Parse with jq
terraform output -json | jq '.acr_login_server.value'
```

## Monitoring State Changes

### Diff Before Apply
```bash
terraform plan -out=tfplan
terraform show tfplan
```

### Show Recent Changes
```bash
terraform state show azurerm_container_app.main
```

### Refresh State
```bash
# Update state file with actual Azure resources
terraform refresh
```

## Performance Optimization

### Parallel Execution
```bash
# Create up to 10 resources in parallel (default is 10)
terraform apply -parallelism=20
```

### Large Deployments
For many resources, Terraform parallelization helps, but:
- Some resources have dependencies (respects `depends_on`)
- Azure API rate limits may apply
- Consider staging deployments for very large environments

## Next Steps

1. **Remote State**: Set up Azure Storage backend for team collaboration
2. **CI/CD**: Integrate with GitHub Actions or Azure Pipelines
3. **Validation**: Add `terraform fmt` and `terraform validate` to CI pipeline
4. **Drift Detection**: Run `terraform plan` regularly to detect manual changes
5. **Documentation**: Add comments to resources explaining why they exist

## Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Style Guide](https://developer.hashicorp.com/terraform/language/style)
- [Microsoft Azure Terraform Best Practices](https://learn.microsoft.com/azure/developer/terraform/)
- [Terraform CLI Commands](https://developer.hashicorp.com/terraform/cli/commands)
