# Azure Landing Zone - Terraform Edition

## Project Overview

A production-ready Azure Landing Zone built with **Terraform**, featuring:
- ✅ Virtual Network with 6 subnets (ACR, ACA, Jumpbox, Bastion, APIM, CI/CD)
- ✅ Azure Container Registry (ACR) Premium with private endpoints
- ✅ Azure Container Apps (ACA) with internal load balancer
- ✅ Azure API Management (APIM) StandardV2 with private endpoints
- ✅ Optional GitHub Actions self-hosted runner (Container Apps Job)
- ✅ Pre-built .NET 8 Minimal API application
- ✅ Linux Jumpbox VM for administration
- ✅ Azure Bastion for secure remote access
- ✅ Log Analytics for monitoring and diagnostics
- ✅ Managed Identity integration (no secrets in code)

## Quick Links

- **[PREREQUISITES.md](PREREQUISITES.md)** - ⭐ START HERE - Validate permissions, tools, and access
- **[README.md](README.md)** - Architecture, components, deployment, troubleshooting
- **[QUICKSTART.md](QUICKSTART.md)** - 5-minute deployment guide with step-by-step commands
- **[GITHUB-ACTIONS-QUICKSTART.md](GITHUB-ACTIONS-QUICKSTART.md)** - Automated CI/CD with GitHub Actions (recommended)
- **[DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md)** - Step-by-step deployment verification
- **[POST-DEPLOYMENT-ACCESS.md](POST-DEPLOYMENT-ACCESS.md)** - Access jumpbox VMs and retrieve credentials
- **[TERRAFORM.md](TERRAFORM.md)** - Deep dive into Terraform workflows and advanced usage
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Design decisions, best practices, security, monitoring
- **[CI-CD-RUNNER.md](CI-CD-RUNNER.md)** - Self-hosted GitHub Actions runner setup
- **[DOCKERFILE](Dockerfile)** - Multi-stage container build for .NET app

## File Structure

```
azlz-msfoundry-sandbox-private/
├── infrastructure/
│   └── terraform/                   # Terraform Infrastructure as Code
│       ├── provider.tf              # Azure provider & auth config
│       ├── versions.tf              # Version requirements
│       ├── main.tf                  # Primary resource definitions
│       ├── variables.tf             # Input variable declarations
│       ├── outputs.tf               # Output value definitions
│       └── terraform.tfvars         # Variable values (environment-specific)
├── src/
│   └── webapp/                      # .NET 8 Minimal API application
│       ├── webapp.csproj            # Project file
│       └── Program.cs               # Application code
├── scripts/
│   ├── tf-deploy.sh                 # Terraform deployment (init → apply)
│   ├── tf-plan.sh                   # Terraform plan (init → plan)
│   ├── tf-destroy.sh                # Terraform destroy
│   ├── build-and-push.sh            # Container build & push to ACR
│   └── update-container-app.sh      # Update ACA with new image
├── Dockerfile                       # Multi-stage container build
├── README.md                        # Main documentation
├── QUICKSTART.md                    # Fast deployment guide
├── TERRAFORM.md                     # Terraform deep-dive
├── ARCHITECTURE.md                  # Architecture & best practices
├── .gitignore                       # Git exclusions
└── INDEX.md                         # This file
```

## Getting Started

### Prerequisites
```bash
# Check Azure CLI
az --version

# Check Terraform
terraform --version

# Check Docker
docker --version

# Check .NET SDK (optional)
dotnet --version

# SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azlz-jumpbox -N ""
```

### 1. Quick Deploy (5 minutes)
```bash
# Follow QUICKSTART.md for step-by-step commands
cat QUICKSTART.md

# Or see the 5-minute summary:
# 1. Configure SSH public key in terraform/terraform.tfvars
# 2. cd infrastructure/terraform && terraform init
# 3. terraform apply
# 4. Build & push container image
# 5. Test the application
```

### 2. Detailed Deployment
```bash
# Read full details
cat README.md

# Understand architecture
cat ARCHITECTURE.md

# Learn Terraform specifics
cat TERRAFORM.md
```

## Key Terraform Files

### `provider.tf`
Configures Azure provider and authentication. Uses Azure CLI credentials automatically.

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features { ... }
}
```

### `main.tf`
Contains all resource definitions:
- **Locals**: Derived values, naming conventions
- **Resource Group**: Foundation container
- **Networking**: VNet, subnets, NSGs with security rules
- **Container Registry**: ACR with Premium SKU and private endpoints
- **API Management**: APIM with internal VNet integration
- **Logging**: Log Analytics workspace
- **Identity**: User-assigned managed identity for ACA
- **Container Apps**: Environment and Container App with health checks
- **VM & Bastion**: Jumpbox and Bastion for secure access
- **Private Endpoints**: ACR, APIM, and Container Apps DNS zones

### `variables.tf`
Input variables with defaults:
- Networking (address spaces, subnets)
- Compute (VM size, image)
- Application (container port, replicas)
- Tags and metadata

### `terraform.tfvars`
Environment-specific values:
```hcl
location      = "eastus"
environment   = "dev"
acr_sku       = "Premium"
apim_sku      = "StandardV2"
ssh_public_key = "ssh-rsa AAAA..."  # Your public key
```

### `outputs.tf`
Exports important values:
- Resource IDs and names
- Endpoints (Container App URL)
- Connection info (jumpbox IP, Bastion details)

### `versions.tf`
Version requirements (referenced in provider.tf):
```hcl
terraform {
  required_version = ">= 1.5"
}
```

## Terraform Workflow

```
1. terraform init      # Download provider plugins
   ↓
2. terraform validate  # Check syntax
   ↓
3. terraform plan      # Show what will change
   ↓
4. terraform apply     # Create/update resources
   ↓
5. terraform output    # Get resource endpoints
```

## Common Tasks

### Deploy Infrastructure
```bash
cd infrastructure/terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### View Outputs
```bash
cd infrastructure/terraform
terraform output                    # All outputs
terraform output container_app_url  # Specific output
terraform output -json              # JSON format
```

### Update Configuration
```bash
# Edit terraform.tfvars or use CLI
terraform apply -var="max_replicas=10"
```

### Destroy Infrastructure
```bash
cd infrastructure/terraform
terraform destroy
```

## State Management

**Important**: Terraform maintains a `terraform.tfstate` file:
- **Local state** (default): `.gitignore` prevents accidental commits
- **Remote state** (recommended for teams): Use Azure Storage backend

Configure remote state:
```hcl
# infrastructure/terraform/backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateaccount"
    container_name       = "tfstate"
    key                  = "landing-zone.tfstate"
  }
}
```

## Security Practices

✅ **Network**: Subnets isolated with NSGs  
✅ **Identity**: Managed identity for ACA (no credentials in code)  
✅ **SSH**: Key-based auth on jumpbox (no passwords)  
✅ **Secrets**: .gitignore protects state files  
✅ **Encryption**: TLS in transit, platform encryption at rest  
✅ **Access**: Bastion for secure VM access (no public IP)  

## Monitoring

All logs flow to **Log Analytics Workspace**:
```bash
# Query logs via KQL in Azure Portal
# Or via Azure CLI:
az monitor log-analytics query \
  --workspace $WORKSPACE_ID \
  --analytics-query 'ContainerAppConsoleLogs_CL | limit 100'
```

## Container Application

Pre-built **.NET 8 Minimal API** with:
- `/` - Application info
- `/health` - Health check (for probes)
- `/ready` - Readiness check (for load balancer)
- `/api/info` - Detailed API information
- `/api/environment` - Runtime environment details
- `/api/echo` - Echo service (POST)

## Deployment Options

### Option 1: Script-based (Recommended for CI/CD)
```bash
chmod +x scripts/tf-deploy.sh
scripts/tf-deploy.sh
```

### Option 2: Manual Terraform
```bash
cd infrastructure/terraform
terraform init && terraform apply -auto-approve
```

### Option 3: Step-by-step with Plan Review
```bash
cd infrastructure/terraform
terraform init
terraform plan -out=tfplan
# Review tfplan
terraform apply tfplan
```

## Cost Estimation

### Dev Environment (per month - East US2)

| Component | SKU/Size | Cost |
|-----------|----------|------|
| VNet | - | $0 |
| ACR | Premium | $50 |
| API Management | StandardV2 (1 cap) | $744 |
| ACA | Consumption (1 replica, 0.5 vCPU) | $19 |
| Log Analytics | 30-day retention | $8 |
| Jumpbox VM (Linux) | Standard_B2s | $36 |
| Jumpbox VM (Windows) | Standard_D4s_v5 | $186 |
| Azure Bastion | Basic (hourly) | $377 |
| **Total Dev** | | **~$1,420** |

### Prod Environment (per month - East US2)

| Component | SKU/Size | Cost |
|-----------|----------|------|
| VNet | - | $0 |
| ACR | Premium | $50 |
| API Management | StandardV2 (1 cap) | $744 |
| ACA | Consumption (5 replicas, 0.5 vCPU ea) | $97 |
| Log Analytics | 30-day retention | $8 |
| Jumpbox VM (Linux) | Standard_B2s | $36 |
| Jumpbox VM (Windows) | Standard_D4s_v5 | $186 |
| Azure Bastion | Basic (hourly) | $377 |
| **Total Prod** | | **~$1,498** |

### Cost Optimization Tips

- **ACR Standard**: $10/mo if private endpoints not required
- **APIM**: Use Developer tier ($50/mo) for non-production testing
- **Bastion**: $5-10/day on-demand pricing available; disable when not in use
- **ACA Scaling**: Reduce max_replicas in dev; scale more aggressively in prod
- **Reserved Instances**: Purchase 1-3 year reserved capacity for 20-40% savings
- **Spot VMs**: Use for non-critical workloads to reduce 70% of VM costs

## Next Steps

1. **Deploy**: Follow [QUICKSTART.md](QUICKSTART.md)
2. **Learn Terraform**: Read [TERRAFORM.md](TERRAFORM.md)
3. **Understand Architecture**: Review [ARCHITECTURE.md](ARCHITECTURE.md)
4. **Set up Remote State**: For team environments
5. **Integrate CI/CD**: GitHub Actions, Azure Pipelines
6. **Add More Services**: Key Vault, Database, API Management

## Resources

- [Terraform Docs](https://www.terraform.io/docs)
- [Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)
- [Container Apps Best Practices](https://learn.microsoft.com/azure/container-apps/)

## Support

- **Terraform Issues**: [GitHub Issues](https://github.com/hashicorp/terraform-provider-azurerm/issues)
- **Azure Issues**: [Microsoft Support](https://support.microsoft.com/azure)
- **This Project**: See documentation files above

---

**Ready to deploy? Start with [QUICKSTART.md](QUICKSTART.md)** 🚀
