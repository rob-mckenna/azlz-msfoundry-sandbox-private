# Quick Start Guide

## Recommended: Automated Deployment with GitHub Actions

For automated CI/CD across DEV, QA, and PROD environments (recommended):
- **Time**: 10 minutes setup
- **Reference**: [GITHUB-ACTIONS-QUICKSTART.md](GITHUB-ACTIONS-QUICKSTART.md)
- **Benefits**: Automated testing, health checks, approval gates for production

---

## Alternative: Manual Terraform Deployment

### 5-Minute Deployment

### Step 1: Prerequisites Check
```bash
# Verify Azure CLI
az version

# Verify Terraform
terraform version

# Verify Docker
docker version

# Verify .NET SDK (optional, for local testing)
dotnet --version
```

### Step 2: Set Environment Variables
```bash
# Linux/Mac
export RESOURCE_GROUP=azlz-rg
export LOCATION=eastus

# Windows PowerShell
$env:RESOURCE_GROUP = "azlz-rg"
$env:LOCATION = "eastus"
```

### Step 3: Configure Terraform Variables

**Required: Generate or Get Your SSH Public Key**

If you don't already have an SSH key pair, generate one:
```bash
# Generate a new SSH key pair (one time)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azlz-jumpbox -N ""

# This creates two files:
#   ~/.ssh/azlz-jumpbox          (private key - keep secret)
#   ~/.ssh/azlz-jumpbox.pub      (public key - paste into terraform.tfvars)

# Display your public key (copy the entire output)
cat ~/.ssh/azlz-jumpbox.pub
```

**Required: Edit terraform.tfvars**

1. Open the configuration file:
   ```bash
   # Linux/Mac
   nano infrastructure/terraform/terraform.tfvars
   
   # Or use your preferred editor
   code infrastructure/terraform/terraform.tfvars
   ```

2. Find this line (around line 43):
   ```hcl
   ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDR3b7fZ5N7VvN8..."
   ```

3. Replace the placeholder with your public key (from `cat ~/.ssh/azlz-jumpbox.pub`):
   ```hcl
   ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABGQ..." # Your actual key here
   ```

**Optional: Adjust Other Settings**

Review these settings in terraform.tfvars and adjust if needed:

```hcl
# Location where resources will be created
location    = "eastus"              # Change to preferred Azure region

# Environment name (prefix for resource names)
environment = "dev"                 # Or "qa", "prod"

# Container sizing
min_replicas = 1
max_replicas = 5
```

**APIM Publisher Settings (Set Separately - Not in terraform.tfvars)**

The API Management publisher name and email are NOT set in terraform.tfvars for security. You must provide them via one of these methods:

**Method A: Environment Variables** (Easiest)
```bash
export TF_VAR_apim_publisher_name="Your Organization"
export TF_VAR_apim_publisher_email="admin@yourdomain.com"
```

**Method B: Local tfvars File** (Recommended)
```bash
# Create local.tfvars
cat > infrastructure/terraform/local.tfvars << EOF
apim_publisher_name  = "Your Organization"
apim_publisher_email = "admin@yourdomain.com"
EOF
```

**Method C: CLI Flags** (One-time deployments)
```bash
terraform apply \
  -var="apim_publisher_name=Your Organization" \
  -var="apim_publisher_email=admin@yourdomain.com"
```

**Example terraform.tfvars After Editing:**
```hcl
location    = "eastus2"
environment = "dev"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDxN4b7k2..."
# Note: apim_publisher_name and apim_publisher_email set via env vars above
```

**Save and Exit**
- If using `nano`: Press `Ctrl+O` → Enter → `Ctrl+X`
- If using VS Code: `Ctrl+S`

**⚠️ Security: Don't commit terraform.tfvars to git**

The `terraform.tfvars` file contains your SSH public key and should NEVER be committed to source control. The `.gitignore` will automatically exclude it. You have three options:

**Option 1: Use Environment Variables** (Recommended for CI/CD)
```bash
# Instead of editing terraform.tfvars, set environment variable:
export TF_VAR_ssh_public_key="$(cat ~/.ssh/azlz-jumpbox.pub)"

# Then terraform will use the environment variable automatically
cd infrastructure/terraform
terraform apply
```

**Option 2: Create Local .tfvars File** (Recommended for local development)
```bash
# Create a local copy that won't be committed
cp infrastructure/terraform/terraform.tfvars infrastructure/terraform/local.tfvars

# Edit local.tfvars with your SSH key
nano infrastructure/terraform/local.tfvars

# Use it when running terraform
cd infrastructure/terraform
terraform apply -var-file=local.tfvars

# Note: local.tfvars is in .gitignore and won't be committed
```

**Option 3: Use terraform.tfvars.example as Template** (For teams)
```bash
# 1. Create template file (commit to git)
cp infrastructure/terraform/terraform.tfvars infrastructure/terraform/terraform.tfvars.example
# Remove SSH key from example: ssh_public_key = "ssh-rsa REPLACE_WITH_YOUR_KEY"

# 2. Create local copy (don't commit)
cp infrastructure/terraform/terraform.tfvars.example infrastructure/terraform/terraform.tfvars

# 3. Edit terraform.tfvars locally with your SSH key
# terraform.tfvars is in .gitignore and won't be committed
```

### Step 4: Deploy Infrastructure
```bash
# Navigate to terraform directory
cd infrastructure/terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# If you used environment variables for SSH key and APIM settings:
# Just run terraform plan - it will use the environment variables

# If you created local.tfvars with your settings:
# Specify it when running terraform
terraform plan -var-file=local.tfvars -out=tfplan

# If using CLI flags instead:
# Add them to both plan and apply commands
# terraform plan \
#   -var="apim_publisher_name=Your Organization" \
#   -var="apim_publisher_email=admin@yourdomain.com" \
#   -out=tfplan

# Apply plan
terraform apply tfplan
```

### Step 5: Build and Push Container Image

⚠️ **Important: ACR Is Private-Only by Default**

By default, the Azure Container Registry is configured with a **private endpoint and no public access**. This means:
- ✅ Your laptop **cannot directly push** to the ACR from the public internet (security feature)
- ✅ Recommended: Use GitHub Actions workflows instead (see [GITHUB-ACTIONS-QUICKSTART.md](GITHUB-ACTIONS-QUICKSTART.md))

**To push from your laptop, choose ONE of these approaches:**

**Approach A: Use GitHub Actions** (Recommended - Most Secure)
```bash
# Just push code to GitHub - workflows handle build/push automatically
git commit -m "Your changes"
git push origin develop  # Triggers automatic build & deployment
# See: GITHUB-ACTIONS-QUICKSTART.md
```

**Approach B: Temporarily Allow Public Access** (Development Only)
```bash
# EDIT: infrastructure/terraform/terraform.tfvars
enable_acr_private_endpoint = false

# Redeploy to enable public access temporarily
cd infrastructure/terraform
terraform apply

# Now you can push from your laptop:
```

**Approach C: Build & Push from Jumpbox** (Inside VNet)
```bash
# SSH to jumpbox via Azure Bastion, then build/push there
```

---

## If Using Approach B (Public ACR for Local Development)

After setting `enable_acr_private_endpoint = false` and redeploying:

**✅ Run this on your local machine**

```bash
# Navigate back to project root
cd ../..

# Get ACR name from terraform output
ACR_NAME=$(cd infrastructure/terraform && terraform output -raw acr_name)

# Login to Azure
az login

# Login to ACR (now publicly accessible)
az acr login --name $ACR_NAME

# Build image
docker build -t ${ACR_NAME}.azurecr.io/azlz-app:latest -f Dockerfile .

# Push image
docker push ${ACR_NAME}.azurecr.io/azlz-app:latest

echo "✓ Image pushed to: ${ACR_NAME}.azurecr.io/azlz-app:latest"

# ⚠️  IMPORTANT: Re-enable private endpoint for production security:
# Set enable_acr_private_endpoint = true in terraform.tfvars
# Then redeploy: terraform apply
```

### Step 6: Verify Deployment
**⚠️ Container App Testing Requires Jumpbox Access**

By default, the Container App is configured with **internal-only access** (not accessible from the internet). To test it, you have two options:

**Option A: Access via Jumpbox (Recommended for production-like setup)**
1. SSH to the jumpbox via Azure Bastion (see "Accessing the Jumpbox via Bastion" section below)
2. From the jumpbox, test the application:

```bash
# Get Container App FQDN
CONTAINER_APP_FQDN=$(az containerapp show --name azlz-app --resource-group azlz-rg \
  --query properties.configuration.ingress.fqdn -o tsv)

# Test from jumpbox
curl http://${CONTAINER_APP_FQDN}/
curl http://${CONTAINER_APP_FQDN}/api/info
```

**Option B: Enable External Access (For development/testing only)**
```bash
# Edit terraform configuration
cd infrastructure/terraform

# Update terraform.tfvars
# Set: enable_container_app_external = true

# Redeploy
terraform apply

# Now you can test locally
CONTAINER_APP_URL=$(terraform output -raw container_app_fqdn)
curl https://${CONTAINER_APP_URL}/
```

## Accessing the Jumpbox via Bastion

### Via Azure Portal
1. Navigate to your Bastion resource in the Azure Portal
2. Click "Bastion" → select the Jumpbox VM
3. Choose "SSH" connection method
4. Use username: `azureuser`

### Via Terraform Outputs
```bash
# Get jumpbox details
terraform output -json

# Get jumpbox private IP
terraform output jumpbox_private_ip
```

## Key Management (SSH Keys for Jumpbox)

### Generate SSH Key Pair
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azlz-jumpbox -N ""
```

### Update Terraform Variables with Your Public Key
1. Get your public key:
   ```bash
   cat ~/.ssh/azlz-jumpbox.pub
   ```

2. Update `infrastructure/terraform/terraform.tfvars`:
   ```hcl
   ssh_public_key = "<YOUR-PUBLIC-KEY-HERE>"
   ```

3. Redeploy:
   ```bash
   cd infrastructure/terraform
   terraform apply
   ```

## Application Testing

### Local Testing (Before Container Deployment)
```bash
cd src/webapp
dotnet restore
dotnet run

# In another terminal
curl http://localhost:5000/
curl http://localhost:5000/health
curl http://localhost:5000/api/info
```

### Container Testing
```bash
# Build locally
docker build -t azlz-app:test -f Dockerfile .

# Run container
docker run -p 8080:8080 azlz-app:test

# Test in another terminal
curl http://localhost:8080/
curl http://localhost:8080/api/info
```

### Production Testing (After ACA Deployment)
```bash
# Get FQDN from Terraform output
CONTAINER_APP_URL=$(cd infrastructure/terraform && terraform output -raw container_app_url)

# Test endpoints
curl ${CONTAINER_APP_URL}/
curl ${CONTAINER_APP_URL}/api/info
curl ${CONTAINER_APP_URL}/api/environment

# POST test
curl -X POST ${CONTAINER_APP_URL}/api/echo \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello from Bastion!"}'
```

## Monitoring

### View Container App Logs
```bash
# Get ACR name and resource group from terraform output
RESOURCE_GROUP=$(cd infrastructure/terraform && terraform output -raw resource_group_name)

az containerapp logs show \
  --name azlz-app \
  --resource-group $RESOURCE_GROUP \
  --container-name azlz-app \
  --tail 50
```

### View Terraform State
```bash
# List all resources
cd infrastructure/terraform
terraform state list

# Show specific resource
terraform state show azurerm_container_app.main
```

### Query Log Analytics via Terraform Output
```bash
# Get workspace name
cd infrastructure/terraform
WORKSPACE=$(terraform output -raw log_analytics_workspace_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

# Query logs
az monitor log-analytics query \
  --workspace $WORKSPACE \
  --resource-group $RESOURCE_GROUP \
  --analytics-query 'ContainerAppConsoleLogs_CL | tail 50'
```

## Scaling

### Manual Scaling via Terraform
```bash
cd infrastructure/terraform

# Edit terraform.tfvars
# Change max_replicas and/or min_replicas

# Apply changes
terraform apply
```

### View Current Replicas
```bash
cd infrastructure/terraform
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

az containerapp show \
  --name azlz-app \
  --resource-group $RESOURCE_GROUP \
  --query "properties.template.scale"
```

## Updating Application Code

### After Code Changes
```bash
# 1. Get ACR and resource group names from terraform
cd infrastructure/terraform
ACR_NAME=$(terraform output -raw acr_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
cd ../..

# 2. Update version tag
VERSION=1.1.0

# 3. Build new image
docker build -t ${ACR_NAME}.azurecr.io/azlz-app:${VERSION} -f Dockerfile .
docker push ${ACR_NAME}.azurecr.io/azlz-app:${VERSION}

# 4. Update container app
CONTAINER_APP_NAME=$(terraform output -raw container_app_name)

az containerapp update \
  --name ${CONTAINER_APP_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --image ${ACR_NAME}.azurecr.io/azlz-app:${VERSION}
  --resource-group $RESOURCE_GROUP \
  --image ${ACR_NAME}.azurecr.io/azlz-app:${VERSION}
```

## Cleanup

```bash
# Navigate to terraform directory
cd infrastructure/terraform

# Destroy all infrastructure
terraform destroy

# Or use the script (Linux/Mac)
chmod +x ../../scripts/tf-destroy.sh
../../scripts/tf-destroy.sh
```

## Troubleshooting

### Problem: "Failed to validate Terraform configuration"
```bash
cd infrastructure/terraform

# Validate template
terraform validate

# Show errors
terraform validate -json
```

### Problem: "Cannot push to ACR"
```bash
# Get ACR name from terraform output
ACR_NAME=$(cd infrastructure/terraform && terraform output -raw acr_name)

# Verify ACR login
az acr login --name $ACR_NAME

# Check if image repository exists
az acr repository list --name $ACR_NAME
```

### Problem: "Container App won't start"
```bash
cd infrastructure/terraform
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

# Check image status
ACR_NAME=$(terraform output -raw acr_name)
az acr repository show -n $ACR_NAME --image azlz-app

# View deployment logs
az containerapp logs show -n azlz-app -g $RESOURCE_GROUP --container-name azlz-app
```

### Problem: "Terraform state is locked"
```bash
cd infrastructure/terraform

# Force unlock (use with caution)
terraform force-unlock <LOCK-ID>

# View state
terraform state list
```

## Advanced Topics

### Custom Domains
```bash
cd infrastructure/terraform
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

# Add custom domain to Container App
az containerapp hostname add \
  --name azlz-app \
  --resource-group $RESOURCE_GROUP \
  --hostname myapp.example.com \
  --certificate-id <path-to-pfx-certificate>
```

### Environment Variables
```bash
cd infrastructure/terraform

# Add to terraform.tfvars or use -var flag
# Then update container environment variables in main.tf template
terraform apply -var="additional_env_vars=LOG_LEVEL=Debug"
```

### State Management
```bash
# View current state
terraform state list

# Show specific resource
terraform state show azurerm_container_app.main

# Remove resource from state (careful!)
terraform state rm azurerm_resource_group.main
```

### Terraform Workspaces (Multiple Environments)
```bash
cd infrastructure/terraform

# Create workspace for staging
terraform workspace new staging

# Switch to workspace
terraform workspace select staging

# Apply with different tfvars
terraform apply -var-file="staging.tfvars"
```

## Next Steps

1. **Set up CI/CD**: Configure GitHub Actions or Azure Pipelines
2. **Add Key Vault**: Store secrets securely
3. **Enable Application Insights**: Advanced monitoring and diagnostics
4. **Configure Custom Domain**: Map your domain to the Container App
5. **Implement Disaster Recovery**: Set up backup and failover strategies
6. **Add Database**: Integrate Azure SQL or Cosmos DB
7. **API Management**: Deploy Azure API Management for advanced API scenarios

## Getting Help

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Best Practices](https://developer.hashicorp.com/terraform/language/style)
- [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [Azure CLI Documentation](https://learn.microsoft.com/cli/azure/)
