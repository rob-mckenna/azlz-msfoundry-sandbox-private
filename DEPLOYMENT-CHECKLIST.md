# Terraform Deployment Checklist

**Note**: For automated deployment using GitHub Actions, see [GITHUB-ACTIONS-QUICKSTART.md](../GITHUB-ACTIONS-QUICKSTART.md) instead.

This checklist is for manual Terraform deployments.

## Pre-Deployment

- [ ] **Azure Account Ready**
  ```bash
  az login
  az account show
  ```

- [ ] **Terraform Installed**
  ```bash
  terraform version
  # Should be >= 1.5
  ```

- [ ] **Azure CLI Installed**
  ```bash
  az --version
  # Should be recent version
  ```

- [ ] **SSH Key Pair Generated**
  ```bash
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/azlz-jumpbox -N ""
  cat ~/.ssh/azlz-jumpbox.pub  # Copy for next step
  ```

- [ ] **SSH Public Key Added to terraform.tfvars**
  ```bash
  # Edit: infrastructure/terraform/terraform.tfvars
  # Replace: ssh_public_key = "ssh-rsa AAAA..."
  ```

- [ ] **Docker Installed** (for container image build)
  ```bash
  docker --version
  ```

- [ ] **Review Configuration**
  - [ ] Check `infrastructure/terraform/terraform.tfvars`
  - [ ] Verify location (eastus, westus, etc.)
  - [ ] Verify environment name (dev, staging, prod)
  - [ ] Verify resource sizing (vm_size, acr_sku, replicas)

## Terraform Deployment Steps

### Step 1: Initialize
- [ ] Navigate to terraform directory
  ```bash
  cd infrastructure/terraform
  ```

- [ ] Initialize Terraform
  ```bash
  terraform init
  ```
  ✓ Should create `.terraform/` directory  
  ✓ Should show "Terraform has been successfully configured!"

- [ ] Verify initialization
  ```bash
  ls -la .terraform/providers/
  ```

### Step 2: Validate
- [ ] Validate Terraform configuration
  ```bash
  terraform validate
  ```
  ✓ Should show "Success!"

- [ ] Check formatting (optional)
  ```bash
  terraform fmt -recursive
  ```

### Step 3: Plan
- [ ] Create execution plan
  ```bash
  terraform plan -out=tfplan
  ```
  ✓ Should show resource creation plan  
  ✓ Review output for any errors

- [ ] Check plan output
  ```bash
  terraform show tfplan
  # Review resource types and names
  ```

### Step 4: Apply
- [ ] Apply configuration
  ```bash
  terraform apply tfplan
  ```
  ✓ Should begin creating resources  
  ✓ Watch for completion message

- [ ] Monitor progress
  - [ ] Check Azure Portal for resource creation
  - [ ] Wait for all resources to finish

- [ ] Verify all resources created
  ```bash
  terraform state list
  # Should show ~30 resources
  ```

### Step 5: Retrieve Outputs
- [ ] Get all outputs
  ```bash
  terraform output
  ```
  ✓ Should show resource IDs, names, endpoints

- [ ] Save important values
  ```bash
  terraform output -json > outputs.json
  
  ACR_NAME=$(terraform output -raw acr_name)
  RESOURCE_GROUP=$(terraform output -raw resource_group_name)
  CONTAINER_APP_URL=$(terraform output -raw container_app_url)
  
  echo "ACR: $ACR_NAME"
  echo "RG: $RESOURCE_GROUP"
  echo "URL: $CONTAINER_APP_URL"
  ```

## Container Image Deployment

### Step 6: Build Container Image
- [ ] Navigate to project root
  ```bash
  cd ../..  # From infrastructure/terraform
  ```

- [ ] Build Docker image
  ```bash
  ACR_NAME=$(cd infrastructure/terraform && terraform output -raw acr_name)
  docker build -t ${ACR_NAME}.azurecr.io/azlz-app:latest -f Dockerfile .
  ```
  ✓ Should complete without errors
  ✓ Image should be ~200-300 MB

- [ ] Verify image
  ```bash
  docker images | grep azlz-app
  ```

### Step 7: Push to ACR
- [ ] Login to Azure
  ```bash
  az login
  ```

- [ ] Login to ACR
  ```bash
  az acr login --name $ACR_NAME
  ```
  ✓ Should show "Login Succeeded"

- [ ] Push image
  ```bash
  docker push ${ACR_NAME}.azurecr.io/azlz-app:latest
  ```
  ✓ Should show upload progress and completion

- [ ] Verify image in ACR
  ```bash
  az acr repository list --name $ACR_NAME
  # Should show: ["azlz-app"]
  ```

## Post-Deployment Verification

### Step 8: Verify Infrastructure
- [ ] Check resource group
  ```bash
  az group show --name $RESOURCE_GROUP
  ```

- [ ] List all resources
  ```bash
  az resource list --resource-group $RESOURCE_GROUP --output table
  ```
  ✓ Should show 20+ resources

- [ ] Verify Container App
  ```bash
  az containerapp show --name azlz-app --resource-group $RESOURCE_GROUP
  ```
  ✓ Should show active container app

- [ ] Check Container App status
  ```bash
  az containerapp show --name azlz-app --resource-group $RESOURCE_GROUP \
    --query "properties.template.containers[0].name"
  ```

### Step 9: Test Application
- [ ] Get Container App URL (wait a few seconds for deployment)
  ```bash
  sleep 30  # Wait for app to be ready
  CONTAINER_APP_URL=$(terraform -C infrastructure/terraform output -raw container_app_url)
  echo $CONTAINER_APP_URL
  ```

- [ ] Test basic endpoint
  ```bash
  curl ${CONTAINER_APP_URL}/
  # Should return JSON with app info
  ```

- [ ] Test health endpoints
  ```bash
  curl ${CONTAINER_APP_URL}/health
  curl ${CONTAINER_APP_URL}/ready
  ```

- [ ] Test API endpoints
  ```bash
  curl ${CONTAINER_APP_URL}/api/info
  curl ${CONTAINER_APP_URL}/api/environment
  ```

- [ ] Test POST endpoint
  ```bash
  curl -X POST ${CONTAINER_APP_URL}/api/echo \
    -H "Content-Type: application/json" \
    -d '{"message":"Hello Azure!"}'
  ```

### Step 10: Verify Bastion & Jumpbox
- [ ] Check Bastion status
  ```bash
  az network bastion show --name azlz-bastion --resource-group $RESOURCE_GROUP
  ```

- [ ] Get Linux jumpbox details
  ```bash
  JUMPBOX_LINUX_IP=$(terraform -C infrastructure/terraform output -raw jumpbox_private_ip)
  echo "Linux Jumpbox Private IP: $JUMPBOX_LINUX_IP"
  ```

- [ ] Get Windows jumpbox details
  ```bash
  JUMPBOX_WINDOWS_IP=$(terraform -C infrastructure/terraform output -raw jumpbox_windows_private_ip)
  echo "Windows Jumpbox Private IP: $JUMPBOX_WINDOWS_IP"
  ```

- [ ] Test Bastion connection to Linux jumpbox (via Azure Portal)
  - [ ] Go to Azure Portal
  - [ ] Navigate to Bastion resource
  - [ ] Click "Connect"
  - [ ] Select Linux jumpbox VM (azlz-jumpbox-vm)
  - [ ] Choose SSH
  - [ ] Enter username: `azureuser`
  - [ ] Should establish connection

- [ ] Test Bastion connection to Windows jumpbox (via Azure Portal)
  - [ ] Go to Azure Portal
  - [ ] Navigate to Bastion resource
  - [ ] Click "Connect"
  - [ ] Select Windows jumpbox VM (azlz-jumpbox-win-vm)
  - [ ] Choose RDP
  - [ ] Enter username: `azureuser`
  - [ ] Enter password: Retrieve from GitHub Secrets (see below)
  - [ ] Should establish RDP connection

**Retrieving Windows Jumpbox Password:**
```bash
# Method 1: Via GitHub Web UI
1. Go to GitHub repository
2. Settings → Secrets and variables → Actions
3. Find WINDOWS_ADMIN_PASSWORD secret
4. Note: You must have repository admin access to view secrets

# Method 2: If password lost/forgotten
# Terraform can output it (if stored in outputs.tf)
cd infrastructure/terraform
terraform output windows_jumpbox_admin_password
# Note: By default, password is NOT output for security
```

**First-Time Windows RDP Connection:**
- Username: `azureuser`
- Password: [from WINDOWS_ADMIN_PASSWORD GitHub Secret]
- You may be prompted to change password on first login
- Recommend updating to a new strong password

### Step 11: Check Logging
- [ ] Verify Log Analytics workspace
  ```bash
  LAW_NAME=$(terraform -C infrastructure/terraform output -raw log_analytics_workspace_name)
  az monitor log-analytics workspace show --name $LAW_NAME --resource-group $RESOURCE_GROUP
  ```

- [ ] View recent logs (may take a few minutes to populate)
  ```bash
  # Via Azure Portal or CLI
  az monitor log-analytics query \
    --workspace $WORKSPACE_ID \
    --analytics-query 'ContainerAppConsoleLogs_CL | limit 10'
  ```

## Troubleshooting During Deployment

- [ ] **Terraform init fails**
  - Check internet connection
  - Verify Azure CLI is configured
  - Run: `terraform init -upgrade`

- [ ] **Terraform plan fails**
  - Run: `terraform validate`
  - Check SSH public key format in tfvars
  - Check all variable values are valid

- [ ] **Container App won't start**
  - Check image pushed to ACR: `az acr repository list -n $ACR_NAME`
  - Check app logs: `az containerapp logs show -n azlz-app -g $RESOURCE_GROUP`
  - Wait 2-3 minutes for initial deployment

- [ ] **Can't access application**
  - Verify container app is active: `az containerapp show ...`
  - Check URL is correct: `terraform output container_app_url`
  - Wait for DNS propagation (can take a few minutes)
  - Check NSG allows inbound 80/443

- [ ] **Bastion connection fails**
  - Verify Bastion is deployed and active
  - Check NSG rules allow Bastion → Jumpbox on port 22
  - Verify jumpbox VM is in "Running" state

## Clean Up (if needed)

- [ ] **Destroy all resources** (caution: cannot undo)
  ```bash
  cd infrastructure/terraform
  terraform destroy
  ```
  ✓ Should show resources being deleted
  ✓ Wait for completion

- [ ] **Verify cleanup**
  ```bash
  az resource list --resource-group $RESOURCE_GROUP
  # Should be empty or show only dependencies
  ```

- [ ] **Delete resource group** (if needed)
  ```bash
  az group delete --name $RESOURCE_GROUP --yes
  ```

## Documentation References

- [ ] Read [README.md](../README.md) for architecture overview
- [ ] Read [QUICKSTART.md](../QUICKSTART.md) for quick reference
- [ ] Read [TERRAFORM.md](../TERRAFORM.md) for advanced Terraform topics
- [ ] Read [ARCHITECTURE.md](../ARCHITECTURE.md) for design decisions
- [ ] Read [POST-DEPLOYMENT-ACCESS.md](../POST-DEPLOYMENT-ACCESS.md) for accessing VMs and retrieving credentials

## Notes

**Deployment Date**: _______________  
**Environment**: _______________  
**Resource Group**: _______________  
**ACR Name**: _______________  
**Container App URL**: _______________  
**Completed By**: _______________  

## Sign-Off

- [ ] All infrastructure deployed successfully
- [ ] Container application running and accessible
- [ ] Logging and monitoring configured
- [ ] Team trained on Terraform workflows
- [ ] Documentation reviewed and understood
- [ ] Deployment documented for future reference

---

**Deployment Complete!** 🎉
