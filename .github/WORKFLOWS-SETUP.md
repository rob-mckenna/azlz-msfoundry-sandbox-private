# GitHub Actions Workflows Setup

## Overview

The Azure Landing Zone includes four GitHub Actions workflows to automate building, testing, and deploying your infrastructure:

1. **ci-cd.yml** - Build Docker image, run tests, deploy to Container Apps (automatically triggered on push)
2. **deploy-infrastructure.yml** - Deploy/update infrastructure with Terraform (manual trigger)
3. **test.yml** - Run unit tests and code quality checks (on push or manual trigger)

## Prerequisites

### 1. GitHub Environments

Create three environments in GitHub:

**Settings → Environments → New environment**

- **dev**
- **qa**
- **prod** (with approval requirement)

For **prod** environment: Add protection rule "Require approval before deployment"

### 2. Required GitHub Secrets

Configure these secrets **per environment** (Settings → Secrets and variables → Actions):

#### Common Secrets (All Environments)

```
REGISTRY_URL              - Your ACR login server (e.g., myacr.azurecr.io)
REGISTRY_USERNAME         - ACR admin user (or service principal)
REGISTRY_PASSWORD         - ACR admin password (or service principal password)
SSH_PUBLIC_KEY            - SSH public key for jumpbox VMs (from ~/.ssh/azlz-jumpbox.pub)
```

#### Environment-Specific Secrets

For each environment (DEV, QA, PROD), add:

```
{ENV}_AZURE_CREDENTIALS        - Azure credentials JSON for service principal
{ENV}_RESOURCE_GROUP           - Azure resource group name
{ENV}_REGISTRY_NAME            - ACR instance name
{ENV}_TF_BACKEND_RG            - Terraform state backend resource group
{ENV}_TF_BACKEND_STORAGE       - Terraform state storage account name
{ENV}_TF_BACKEND_CONTAINER     - Terraform state blob container name
```

### Example Configuration

**For DEV environment:**
```
DEV_AZURE_CREDENTIALS          = (JSON from service principal)
DEV_RESOURCE_GROUP             = azlz-dev-rg
DEV_REGISTRY_NAME              = azlzacrdev
DEV_TF_BACKEND_RG              = azlz-terraform-state
DEV_TF_BACKEND_STORAGE         = azlztfstatedev
DEV_TF_BACKEND_CONTAINER       = dev
SSH_PUBLIC_KEY                 = (from ~/.ssh/azlz-jumpbox.pub)
WINDOWS_ADMIN_PASSWORD         = (strong 12-123 char password)
```

**For QA environment:**
```
QA_AZURE_CREDENTIALS           = (JSON from service principal)
QA_RESOURCE_GROUP              = azlz-qa-rg
QA_REGISTRY_NAME               = azlzacrqa
QA_TF_BACKEND_RG               = azlz-terraform-state
QA_TF_BACKEND_STORAGE          = azlztfstateqa
QA_TF_BACKEND_CONTAINER        = qa
SSH_PUBLIC_KEY                 = (from ~/.ssh/azlz-jumpbox.pub)
WINDOWS_ADMIN_PASSWORD         = (strong 12-123 char password)
```

**For PROD environment:**
```
PROD_AZURE_CREDENTIALS         = (JSON from service principal)
PROD_RESOURCE_GROUP            = azlz-prod-rg
PROD_REGISTRY_NAME             = azlzacrprod
PROD_TF_BACKEND_RG             = azlz-terraform-state
PROD_TF_BACKEND_STORAGE        = azlztfstateprod
PROD_TF_BACKEND_CONTAINER      = prod
SSH_PUBLIC_KEY                 = (from ~/.ssh/azlz-jumpbox.pub)
WINDOWS_ADMIN_PASSWORD         = (strong 12-123 char password)
```

### 3. Create Azure Service Principals

For each environment, create a service principal with Azure CLI:

```bash
# For DEV
az ad sp create-for-rbac \
  --name "github-actions-dev" \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --json-auth > dev-credentials.json

# For QA
az ad sp create-for-rbac \
  --name "github-actions-qa" \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --json-auth > qa-credentials.json

# For PROD
az ad sp create-for-rbac \
  --name "github-actions-prod" \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --json-auth > prod-credentials.json
```

Copy the JSON output into the corresponding `{ENV}_AZURE_CREDENTIALS` secret.

### 4. Create Terraform State Backend

Set up Azure Storage for Terraform state (one time):

```bash
# Variables
RESOURCE_GROUP="azlz-terraform-state"
STORAGE_ACCOUNT="azlztfstate"
CONTAINER="dev"
LOCATION="eastus"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account
az storage account create \
  --name ${STORAGE_ACCOUNT}dev \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS

# Create blob container
az storage container create \
  --name dev \
  --account-name ${STORAGE_ACCOUNT}dev

# Repeat for QA and PROD:
# - ${STORAGE_ACCOUNT}qa / ${STORAGE_ACCOUNT}prod
# - containers: qa / prod
```

## Workflow Triggers

### CI/CD Workflow (ci-cd.yml)

**Automatic Triggers:**
- Push to `main` branch → Deploy to **PROD**
- Push to `qa` branch → Deploy to **QA**
- Push to `develop` branch → Deploy to **DEV**

**Manual Trigger:**
- Workflow dispatch with environment selection

**Skips if:**
- Push doesn't change `src/`, `Dockerfile`, or workflow file
- Branch is not main/develop/qa

**PROD Deployment Requires:** Approval (set in environment protection rules)

### Infrastructure Workflow (deploy-infrastructure.yml)

**Manual trigger only** - Select:
- Environment: dev, qa, or prod
- Action: plan, apply, or destroy

**PROD Operations Require:** Approval

### Test Workflow (test.yml)

**Automatic Triggers:**
- Push to develop/qa/main branches
- Pull requests to main/develop

**Manual Trigger:**
- Workflow dispatch anytime

## Environment Promotion Flow

```
Develop Branch
     ↓ (auto-deploy to DEV)
DEV Environment
     ↓ (manual merge)
QA Branch
     ↓ (auto-deploy to QA)
QA Environment
     ↓ (manual merge after approval)
Main Branch
     ↓ (auto-deploy to PROD, requires approval)
PROD Environment
```

## Running Workflows Manually

### Deploy Infrastructure

1. Go to **Actions** tab
2. Click **Deploy Infrastructure (Terraform)** workflow
3. Click **Run workflow**
4. Select environment (dev/qa/prod)
5. Select action (plan/apply/destroy)
6. Click green **Run workflow** button

### Build & Deploy

1. Go to **Actions** tab
2. Click **Build, Test & Deploy** workflow
3. Click **Run workflow** with optional environment inputs
4. Click **Run workflow** button

### Run Tests

1. Go to **Actions** tab
2. Click **Test** workflow
3. Click **Run workflow** button

## Monitoring Deployments

### In GitHub

- **Actions tab**: View workflow run progress in real-time
- **Workflow logs**: Detailed step-by-step execution logs
- **Deployment tab**: Track all deployments with status and timestamp
- **Environments**: See current deployment status per environment

### Status Badges

Add to your README.md:

```markdown
[![CI/CD](https://github.com/YOUR_ORG/azlz-msfoundry-sandbox-private/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/YOUR_ORG/azlz-msfoundry-sandbox-private/actions/workflows/ci-cd.yml)
[![Tests](https://github.com/YOUR_ORG/azlz-msfoundry-sandbox-private/actions/workflows/test.yml/badge.svg)](https://github.com/YOUR_ORG/azlz-msfoundry-sandbox-private/actions/workflows/test.yml)
[![Infrastructure](https://github.com/YOUR_ORG/azlz-msfoundry-sandbox-private/actions/workflows/deploy-infrastructure.yml/badge.svg)](https://github.com/YOUR_ORG/azlz-msfoundry-sandbox-private/actions/workflows/deploy-infrastructure.yml)
```

## Troubleshooting

### Workflow Fails at "Azure Login"

**Problem:** Credentials are invalid or expired
**Solution:** 
- Regenerate service principal credentials
- Update `{ENV}_AZURE_CREDENTIALS` secret
- Re-run workflow

### Terraform Apply Fails

**Problem:** State file issues or resource permissions
**Solution:**
- Check Terraform backend credentials
- Verify service principal has Contributor role
- Review Terraform error logs
- Run `terraform show` manually to inspect state

### Container App Not Updating

**Problem:** Image not found or pull failing
**Solution:**
- Verify ACR credentials are correct
- Check container image exists in ACR (format: `myacr.azurecr.io/azlz-app:sha`)
- Verify managed identity has AcrPull role
- Review Container App diagnostics

### Health Check Timeout

**Problem:** Application not responding to `/health` endpoint
**Solution:**
- Application may still be starting (30 second window)
- Check Container App logs in Azure Portal
- Verify application health endpoint is accessible
- Increase timeout in workflow if needed

## Best Practices

1. **Always test in DEV first** - Use develop branch
2. **Use QA for pre-production validation** - Catch issues before prod
3. **Require approvals for PROD** - Prevent accidental deployments
4. **Monitor deployments** - Check Actions tab after push
5. **Rotate credentials** - Regularly update service principal keys
6. **Use branch protection** - Require PR reviews before main branch merges
7. **Tag releases** - Use git tags to mark production deployments
8. **Keep secrets secure** - Never commit credentials or tokens

## Advanced Configuration

### Custom Terraform Variables

Create environment-specific tfvars files:

**infrastructure/terraform/dev.tfvars:**
```hcl
environment = "dev"
location    = "eastus"
vm_size     = "Standard_B2s"
max_replicas = 3
```

**infrastructure/terraform/qa.tfvars:**
```hcl
environment = "qa"
location    = "eastus"
vm_size     = "Standard_B2s"
max_replicas = 5
```

**infrastructure/terraform/prod.tfvars:**
```hcl
environment = "prod"
location    = "eastus"
vm_size     = "Standard_D2s_v3"
max_replicas = 10
```

### Custom Container App Scripts

Edit `scripts/update-container-app.sh` to support environment-specific configurations:

```bash
#!/bin/bash
ENVIRONMENT=$1
IMAGE=$2
# ... load environment-specific settings
```

## Security Considerations

⚠️ **Important Security Notes:**

1. **Service Principals**: Create separate service principals per environment
2. **Minimal Permissions**: Use Contributor role only if necessary; consider custom roles
3. **Rotate Keys**: Regular rotation schedule for service principal keys
4. **Audit Logging**: Enable audit logging in Azure for deployments
5. **Approval Rules**: Require approval for PROD especially
6. **Secret Masking**: GitHub automatically masks secrets in logs
7. **Branch Protection**: Protect main branch, require PR reviews
8. **Token Expiry**: GitHub Actions OIDC tokens are short-lived and scoped

## Next Steps

1. ✅ Create three GitHub Environments (dev, qa, prod)
2. ✅ Create Azure Service Principals
3. ✅ Set up Terraform state backend in Azure
4. ✅ Add all required secrets to GitHub
5. ✅ Create environment-specific tfvars files (optional)
6. ✅ Push code to trigger workflows
7. ✅ Monitor first deployment in Actions tab
8. ✅ Verify deployment succeeded in Azure Portal
