# Post-Deployment Access Guide

After successfully deploying infrastructure, use this guide to access your jumpbox VMs and retrieve credentials.

---

## Overview

Your deployment includes two jumpbox VMs for administrative access:

| VM | OS | Connection Type | Port | Credentials |
|----|----|-----------------|------|-------------|
| **azlz-jumpbox-vm** | Linux Ubuntu 22.04 | SSH | 22 | SSH key pair |
| **azlz-jumpbox-win-vm** | Windows Server 2022 | RDP | 3389 | Username/Password |

**Important**: Neither VM is directly accessible from the internet. All access is through **Azure Bastion**.

---

## Step 1: Verify Deployment

Confirm infrastructure deployed successfully:

```bash
# Set environment variables
RESOURCE_GROUP="azlz-rg"  # or your actual resource group name

# Check resource group exists
az group show --name $RESOURCE_GROUP --query "{name: name, location: location}" -o table

# List resources
az resource list --resource-group $RESOURCE_GROUP --query "[].{name: name, type: type}" -o table

# Should see:
# - Virtual Network
# - Azure Bastion
# - Two VMs (jumpbox-vm and jumpbox-win-vm)
# - Public IPs (3 total)
```

---

## Step 2: Retrieve Credentials

### Linux Jumpbox SSH Key

Your SSH key pair was created during prerequisites setup.

**Finding your SSH private key:**
```bash
# The key should be at:
~/.ssh/azlz-jumpbox

# Verify it exists
ls -la ~/.ssh/azlz-jumpbox

# If it doesn't exist, you'll need to recreate it or ask the person who ran deployment
# (they should securely share the public key from: ~/.ssh/azlz-jumpbox.pub)
```

**What you need:**
- Private key file: `~/.ssh/azlz-jumpbox`
- Public key file: `~/.ssh/azlz-jumpbox.pub`

### Windows Jumpbox Password

The Windows admin password is stored securely in GitHub Secrets.

**Retrieve from GitHub:**

1. Go to your GitHub repository
2. Click **Settings** (top right)
3. In left sidebar: **Secrets and variables** → **Actions**
4. Find **WINDOWS_ADMIN_PASSWORD**
5. Click the secret name
6. Click **Show value** (requires repository admin access)
7. Copy the password

**Important Notes:**
- ⚠️ Only users with **repository admin** access can view secrets
- ⚠️ Secrets are **never logged** in GitHub Actions output
- ⚠️ Each time you click "Show value", GitHub logs the action
- 💾 Save the password securely (password manager recommended)

**If password is unclear or lost:**
```bash
# If you recorded it in terraform outputs:
cd infrastructure/terraform
terraform output -raw windows_jumpbox_admin_password

# If still not available, you'll need to:
# 1. Re-run terraform apply with updated password
# 2. Or reset password in Azure Portal
```

---

## Step 3: Get Jumpbox VM Details

Retrieve the private IP addresses and connection information:

```bash
# Set your resource group
RESOURCE_GROUP="azlz-rg"  # Change to your actual resource group

# Get Linux jumpbox details
echo "=== Linux Jumpbox (azlz-jumpbox-vm) ==="
az vm show --name azlz-jumpbox-vm --resource-group $RESOURCE_GROUP \
  --query "{name: name, provisioningState: provisioningState, powerState: powerState}" -o table

# Get Linux jumpbox private IP
LINUX_PRIVATE_IP=$(az vm list-ip-addresses --name azlz-jumpbox-vm \
  --resource-group $RESOURCE_GROUP --query "[0].virtualMachine.network.privateIpAddresses[0]" -o tsv)

echo "Linux Jumpbox Private IP: $LINUX_PRIVATE_IP"

# Get Windows jumpbox details
echo ""
echo "=== Windows Jumpbox (azlz-jumpbox-win-vm) ==="
az vm show --name azlz-jumpbox-win-vm --resource-group $RESOURCE_GROUP \
  --query "{name: name, provisioningState: provisioningState, powerState: powerState}" -o table

# Get Windows jumpbox private IP
WINDOWS_PRIVATE_IP=$(az vm list-ip-addresses --name azlz-jumpbox-win-vm \
  --resource-group $RESOURCE_GROUP --query "[0].virtualMachine.network.privateIpAddresses[0]" -o tsv)

echo "Windows Jumpbox Private IP: $WINDOWS_PRIVATE_IP"
```

---

## Step 4: Access via Azure Bastion

### What is Azure Bastion?

**Azure Bastion** is a managed service that provides secure RDP/SSH access to VMs without exposing them to the internet. You access it through your browser.

**Benefits:**
- ✅ No public IPs needed on VMs
- ✅ No SSH client or RDP app required (browser-based)
- ✅ Auditable: All connections logged
- ✅ Secure: TLS encrypted connections

### Access Linux Jumpbox via Bastion

**Option 1: Azure Portal (Easiest)**

1. Go to [Azure Portal](https://portal.azure.com)
2. Search for **Bastion** → Select your Bastion resource
3. Click **Connect** (top toolbar)
4. Configure connection:
   - **Vm**: azlz-jumpbox-vm
   - **Authentication Type**: SSH Private Key
   - **Username**: azureuser
   - **Select for Private Key File**:
     - Browse to `~/.ssh/azlz-jumpbox`
     - Or paste the contents
5. Click **Connect**
6. Browser-based SSH terminal will open

**Option 2: Azure CLI (Programmatic)**

```bash
# You can also use Azure CLI to open Bastion connection
# (This opens an SSH tunnel to the bastion)

# For SSH:
az network bastion ssh \
  --name <bastion-name> \
  --resource-group <resource-group> \
  --target-resource-id <vm-id> \
  --auth-type ssh-key \
  --username azureuser \
  --ssh-key ~/.ssh/azlz-jumpbox

# Note: Requires Azure CLI extension for Bastion
az extension add -n bastion
```

### Access Windows Jumpbox via Bastion

**Azure Portal Method (Recommended)**

1. Go to [Azure Portal](https://portal.azure.com)
2. Search for **Bastion** → Select your Bastion resource
3. Click **Connect** (top toolbar)
4. Configure connection:
   - **VM**: azlz-jumpbox-win-vm
   - **Authentication Type**: Password
   - **Username**: azureuser
   - **Password**: [from WINDOWS_ADMIN_PASSWORD GitHub Secret]
5. Click **Connect**
6. RDP session opens in your browser
7. You can now interact with Windows desktop

**First-Time Windows Login:**
- Windows may prompt to change password
- Update to your own strong password if desired
- Subsequent logins will use the new password

---

## Step 5: From Jumpbox - Accessing Other Resources

Once you're on a jumpbox VM, you can access other resources in the VNet:

### From Linux Jumpbox

```bash
# SSH to other VMs (if needed)
ssh azureuser@<private-ip-of-other-vm>

# Test connectivity to Azure Container Registry
az acr login --name <acr-name>
az acr repository list --name <acr-name>

# Test connectivity to Container Apps
curl https://<container-app-fqdn>

# View logs
az containerapp logs show --name azlz-app --resource-group <resource-group>
```

### From Windows Jumpbox

```powershell
# RDP to other resources (if needed)
mstsc /v:<private-ip>

# Test connectivity via PowerShell
Test-NetConnection -ComputerName <azure-resource-ip> -Port 443

# Access Azure resources via Azure CLI (if installed)
az login
az account show
```

---

## Step 6: Troubleshooting Access

### Problem: Can't connect to Bastion

**Check Bastion is deployed:**
```bash
az bastion show --name azlz-bastion --resource-group $RESOURCE_GROUP
# Should show "Succeeded" provisioningState
```

**Check Bastion subnet NSG:**
```bash
# Bastion requires specific inbound rules
az network nsg rule list --nsg-name azlz-bastion-nsg --resource-group $RESOURCE_GROUP -o table
```

### Problem: Bastion connects but VM access fails

**Verify jumpbox VMs are running:**
```bash
az vm get-instance-view --name azlz-jumpbox-vm --resource-group $RESOURCE_GROUP \
  --query instanceView.statuses -o table
# Should show "ProvisioningState: Succeeded" and "PowerState: VM running"
```

**Check VM NSG allows Bastion traffic:**
```bash
# Jumpbox NSG should allow inbound on port 22 (Linux) / 3389 (Windows) from Bastion subnet
az network nsg rule list --nsg-name azlz-jumpbox-nsg --resource-group $RESOURCE_GROUP -o table
```

### Problem: SSH/RDP credentials not working

**Linux (SSH Key):**
```bash
# Verify SSH key has correct permissions
chmod 600 ~/.ssh/azlz-jumpbox
chmod 700 ~/.ssh

# Test SSH connectivity directly (bypassing Bastion)
ssh -i ~/.ssh/azlz-jumpbox -vvv azureuser@<linux-private-ip>
# This will fail (no direct access), but shows if SSH key is valid
```

**Windows (Password):**
- Verify password from GitHub Secrets is correct (copy-paste carefully)
- Check for special characters that might be misinterpreted
- Try resetting password if repeatedly fails

### Problem: "No direct internet access from jumpbox"

This is **expected** and **secure by design**:
- Jumpboxes are in private subnets (no public IPs)
- Cannot directly download from internet
- Can access Azure resources via service endpoints

**Workarounds:**
- Use Azure Container Registry for container images
- Use Key Vault for secrets
- Use VM Managed Identity for Azure API access

---

## Step 7: Post-Access Tasks

### Update Windows Password (Recommended)

For Windows jumpbox, update the GitHub Secret to your new password:

```bash
# From Windows Jumpbox
# 1. Press Ctrl+Alt+Del
# 2. Click "Change a password"
# 3. Enter:
#    - Old password: [from GitHub Secret]
#    - New password: [your new strong password]
#    - Confirm: [repeat new password]
# 4. Login with new password

# Then update GitHub Secret:
# 1. Go to GitHub repository
# 2. Settings → Secrets and variables → Actions
# 3. Update WINDOWS_ADMIN_PASSWORD with new password
# 4. Save
```

### Document Access Procedures

Create internal documentation:
- [ ] Who can access jumpbox VMs
- [ ] When access is needed
- [ ] Approval process for access
- [ ] How to retrieve credentials
- [ ] How to report security incidents

---

## Security Best Practices

✅ **DO:**
- Use SSH keys for Linux (better than passwords)
- Use strong passwords for Windows
- Rotate credentials periodically
- Audit who accesses VMs (check Bastion activity logs)
- Use Bastion instead of exposing VMs to internet

❌ **DON'T:**
- Share SSH private keys via email or chat
- Store passwords in code or documents
- Leave RDP sessions open unattended
- Disable NSGs to "troubleshoot" connectivity
- Use default Azure usernames without changing password

---

## Additional Resources

- [Azure Bastion Documentation](https://learn.microsoft.com/en-us/azure/bastion/bastion-overview)
- [Manage Azure VMs](https://learn.microsoft.com/en-us/azure/virtual-machines/overview)
- [Azure CLI VM Commands](https://learn.microsoft.com/en-us/cli/azure/vm)

---

## Support & Troubleshooting

If you encounter issues:

1. **Check DEPLOYMENT-CHECKLIST.md** for deployment troubleshooting
2. **Check ARCHITECTURE.md** for design explanations
3. **Review Azure Bastion logs** in Azure Portal
   - Monitor → Diagnostic Settings → View logs
4. **Check VM status** in Azure Portal
   - Virtual Machines → Your VM → Status should be "Running"

---

**Document Version**: 1.0  
**Last Updated**: February 6, 2026
