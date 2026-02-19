# GitHub Actions Workflows - Quick Start

> **⚠️ Prerequisites**: Before starting, ensure you meet all requirements in [PREREQUISITES.md](./PREREQUISITES.md). This includes Azure CLI, Terraform, Git, and appropriate Azure/GitHub permissions.

## What Was Created

Your Azure Landing Zone now includes a complete CI/CD pipeline with GitHub Actions workflows that support three environments: **DEV**, **QA**, and **PROD**.

### Files Created

**GitHub Workflows** (`.github/workflows/`):
- ✅ `ci-cd.yml` - Build, test, and deploy application
- ✅ `deploy-infrastructure.yml` - Terraform infrastructure management
- ✅ `test.yml` - Unit tests and code quality checks
- ✅ `README.md` - Workflow documentation

**Setup Guides** (`.github/`):
- ✅ `WORKFLOWS-SETUP.md` - Detailed setup instructions for GitHub and Azure

**Environment-Specific Terraform** (`infrastructure/terraform/`):
- ✅ `dev.tfvars` - Development environment configuration
- ✅ `qa.tfvars` - QA environment configuration
- ✅ `prod.tfvars` - Production environment configuration

## Quick Setup (10 minutes)

### Step 1: Create GitHub Environments

In your repository:
1. Go to **Settings** → **Environments**
2. Click **New environment** (3 times) and create:
   - `dev`
   - `qa`
   - `prod` (with approval requirement)

For **prod** environment:
- Click **Add rule** → "Require reviewers"
- Select approvers (your team)

### Step 2: Create Azure Service Principals

One-time setup for each environment:

```bash
# DEV
az ad sp create-for-rbac \
  --name "github-actions-dev" \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --json-auth > /tmp/dev-creds.json

# QA
az ad sp create-for-rbac \
  --name "github-actions-qa" \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --json-auth > /tmp/qa-creds.json

# PROD
az ad sp create-for-rbac \
  --name "github-actions-prod" \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --json-auth > /tmp/prod-creds.json
```

Copy the JSON output - you'll need it for secrets.

### Step 3: Add GitHub Secrets

For each environment in **Settings → Secrets and variables → Actions**:

**DEV Environment Secrets:**
```
DEV_AZURE_CREDENTIALS          = (paste JSON from service principal)
DEV_RESOURCE_GROUP             = azlz-dev-rg
DEV_REGISTRY_NAME              = azlzacrdev
DEV_TF_BACKEND_RG              = azlz-terraform-state
DEV_TF_BACKEND_STORAGE         = (storage account created in Step 5 for dev)
DEV_TF_BACKEND_CONTAINER       = dev
WINDOWS_ADMIN_PASSWORD         = (strong 12-123 char password)
```

**QA Environment Secrets:**
```
QA_AZURE_CREDENTIALS           = (paste JSON from service principal)
QA_RESOURCE_GROUP              = azlz-qa-rg
QA_REGISTRY_NAME               = azlzacrqa
QA_TF_BACKEND_RG               = azlz-terraform-state
QA_TF_BACKEND_STORAGE          = (storage account created in Step 5 for qa)
QA_TF_BACKEND_CONTAINER        = qa
WINDOWS_ADMIN_PASSWORD         = (strong 12-123 char password)
```

**PROD Environment Secrets:**
```
PROD_AZURE_CREDENTIALS         = (paste JSON from service principal)
PROD_RESOURCE_GROUP            = azlz-prod-rg
PROD_REGISTRY_NAME             = azlzacrprod
PROD_TF_BACKEND_RG             = azlz-terraform-state
PROD_TF_BACKEND_STORAGE        = (storage account created in Step 5 for prod)
PROD_TF_BACKEND_CONTAINER      = prod
WINDOWS_ADMIN_PASSWORD         = (strong 12-123 char password)
```

**All Environments (Repository Secrets):**
```
REGISTRY_URL                   = myregistry.azurecr.io
REGISTRY_USERNAME              = your-acr-username
REGISTRY_PASSWORD              = your-acr-password
```

### Step 4: Store Windows Admin Password in GitHub Secret

If deploying the Windows jumpbox VM:

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `WINDOWS_ADMIN_PASSWORD`
5. Value: Enter a strong password (12-123 characters, must include uppercase, lowercase, number, and special character)
6. Click **Add secret**

### Step 5: Set Up Terraform State Backend

```bash
# Create resource group and storage for terraform state
RESOURCE_GROUP="azlz-terraform-state"
LOCATION="eastus2"

az group create --name $RESOURCE_GROUP --location $LOCATION

# Storage account names must be globally unique (3-24 chars, lowercase/numbers only)
UNIQUE_SUFFIX=$(az account show --query id -o tsv | md5sum | cut -c1-6)

# Create storage accounts for each environment
for ENV in dev qa prod; do
  STORAGE="azlz${ENV}tf${UNIQUE_SUFFIX}"
  echo "Creating storage account: $STORAGE"
  
  az storage account create \
    --name "$STORAGE" \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Standard_LRS
  
  az storage container create \
    --name "$ENV" \
    --account-name "$STORAGE"
done

# Use the printed names for GitHub environment secrets:
# DEV_TF_BACKEND_STORAGE  = storage account created when ENV=dev
# QA_TF_BACKEND_STORAGE   = storage account created when ENV=qa
# PROD_TF_BACKEND_STORAGE = storage account created when ENV=prod
```

### Step 6: First Deployment

```bash
# 1. Go to GitHub Actions
# 2. Click "Deploy Infrastructure (Terraform)"
# 3. Click "Run workflow"
# 4. Select environment: dev
# 5. Select action: plan
# 6. Click "Run workflow"

# Wait for plan to complete, review changes, then:

# 7. Click "Run workflow" again
# 8. Select environment: dev
# 9. Select action: apply
# 10. Click "Run workflow"
```

Or use GitHub CLI:

```bash
gh workflow run deploy-infrastructure.yml \
  -f environment=dev \
  -f action=plan

# After reviewing plan changes:

gh workflow run deploy-infrastructure.yml \
  -f environment=dev \
  -f action=apply
```

### Deploy Application to DEV

Once infrastructure is deployed:

```bash
# Push code to develop branch
git commit -m "Initial deployment" --allow-empty
git push origin develop

# GitHub Actions automatically:
# 1. Builds .NET application
# 2. Runs tests
# 3. Builds Docker image
# 4. Pushes to ACR
# 5. Deploys to Container Apps
# 6. Runs health checks
```

Monitor in **Actions** tab → see live logs as it deploys.

## Deployment Flow by Branch

```
develop → Auto-deploy to DEV
qa      → Auto-deploy to QA
main    → Auto-deploy to PROD (requires approval)
```

### Recommended Workflow

```bash
# 1. Create feature branch
git checkout -b feature/my-feature

# 2. Make changes and push
git push origin feature/my-feature

# 3. Create Pull Request to develop
# (request review from team)

# 4. Merge to develop
# (triggers auto-deployment to DEV)

# 5. Once DEV validated, create PR to qa
# (request review and approval)

# 6. Merge to qa
# (triggers auto-deployment to QA)

# 7. Once QA validated, create PR to main
# (request final approval)

# 8. Merge to main
# (triggers deployment to PROD - requires approval)

# 9. Click "Approve" for PROD deployment in GitHub
```

## Monitoring Deployments

### Real-Time
1. Go to **Actions** tab
2. Click running workflow
3. Watch live logs in each step

### Results
1. Go to **Deployments** tab → see all deployments
2. Go to **Environments** tab → select environment
3. See current deployment status with timestamp

## Environment Specifications

### DEV
- **ACR**: Standard SKU (cost optimization)
- **APIM**: Developer tier
- **Max replicas**: 3
- **VM size**: Standard_B2s
- **CI/CD runner**: Enabled

### QA
- **ACR**: Premium SKU with private endpoints
- **APIM**: StandardV2 (production-like)
- **Max replicas**: 5
- **VM size**: Standard_B2s
- **CI/CD runner**: Enabled

### PROD
- **ACR**: Premium SKU with private endpoints
- **APIM**: StandardV2
- **Max replicas**: 10
- **VM size**: Standard_D2s_v3 (larger)
- **CI/CD runner**: Enabled
- **Requires**: Manual approval for deployment

## Manual Workflow Triggers

### Build and Deploy Anytime

```bash
# Using GitHub UI:
# 1. Actions → "Build, Test & Deploy"
# 2. Click "Run workflow"
# 3. Select environment or leave default
# 4. Click "Run workflow"
```

### Run Tests Only

```bash
# Using GitHub UI:
# 1. Actions → "Test"
# 2. Click "Run workflow"
# 3. Click "Run workflow"
```

### Terraform Operations

```bash
# Using GitHub UI:
# 1. Actions → "Deploy Infrastructure (Terraform)"
# 2. Click "Run workflow"
# 3. Select environment (dev/qa/prod)
# 4. Select action (plan/apply/destroy)
# 5. Click "Run workflow"
```

## Accessing Deployed Applications

### DEV Application
```bash
# Get URL from GitHub Actions output or Azure Portal
az containerapp show --resource-group azlz-dev-rg --name azlz-app \
  --query properties.configuration.ingress.fqdn

# Access via Jumpbox (internal only by default)
# Connect to Windows jumpbox via Azure Bastion (RDP), then:
curl http://<container-app-fqdn>/api/info
```

### Testing Health Endpoint

```bash
# During GitHub Actions deployment, health check automatically validates:
curl https://<container-app-url>/health
curl https://<container-app-url>/ready
```

## Troubleshooting

### Workflow Fails - "Azure Login"
**Solution:** Verify Azure credentials secret is valid JSON from service principal

### Container App Not Updating
**Solution:** Check ACR credentials and verify image was pushed (see build logs)

### Terraform Plan Shows
 Unexpected Changes
**Solution:** Run `terraform plan` manually to inspect current state

### PROD Approval Stuck
**Solution:** Check that approvers have reviewer role on PROD environment

### Application Health Check Fails
**Solution:** Likely still starting up - check logs in Azure Portal

**Full troubleshooting guide:** See `.github/WORKFLOWS-SETUP.md`

## Next Steps

1. ✅ Complete the Quick Setup above
2. ✅ Push a test commit to `develop` branch
3. ✅ Watch first deployment in Actions tab
4. ✅ Verify application deployed in Azure Portal
5. ✅ Promote to QA and PROD once comfortable

## Additional Resources

- **Workflow Details**: `.github/workflows/README.md`
- **Setup Guide**: `.github/WORKFLOWS-SETUP.md`
- **Infrastructure Guide**: `TERRAFORM.md`
- **Application Guide**: `README.md`

## Key Features

✅ **Automated Testing**: Unit tests run on every push  
✅ **Multi-Environment**: DEV/QA/PROD with different configurations  
✅ **Safe Deployments**: PROD requires approval  
✅ **Infrastructure as Code**: Terraform managed via workflows  
✅ **Private Deployments**: Container Apps are internal-only by default  
✅ **Self-Hosted Runner**: GitHub Actions runner inside your VNet  
✅ **Health Checks**: Automatic validation after deployment  
✅ **Full Audit Trail**: All deployments logged in GitHub  

## Security Best Practices

🔐 Service principals per environment  
🔐 Never commit secrets - use GitHub Secrets  
🔐 PROD requires approval before deployment  
🔐 Branch protection rules enforced  
🔐 Secrets masked in workflow logs  
🔐 Regular credential rotation (set reminder)  

---

**Created:** February 5, 2026  
**Ready to use**: Yes - complete the Quick Setup above to get started
