# Post-Deployment Access Guide

After successfully deploying infrastructure, use this guide to access the Windows jumpbox VM and verify private network access.

---

## Overview

Your deployment includes one jumpbox VM for administrative access:

| VM | OS | Connection Type | Port | Credentials |
|----|----|-----------------|------|-------------|
| **azlz-jumpbox-win-vm** | Windows Server 2022 | RDP | 3389 | Username/Password |

**Important**: The VM is not directly accessible from the internet. Access is through **Azure Bastion**.

---

## Step 1: Verify Deployment

```bash
RESOURCE_GROUP="azlz-rg"  # change as needed

az group show --name $RESOURCE_GROUP --query "{name: name, location: location}" -o table
az resource list --resource-group $RESOURCE_GROUP --query "[].{name: name, type: type}" -o table
```

Expected core resources include VNet, Bastion, Windows jumpbox VM, and related public IPs.

---

## Step 2: Retrieve Windows Credentials

The Windows admin password is stored in GitHub Secrets as `WINDOWS_ADMIN_PASSWORD`.

1. Go to repository **Settings**
2. Open **Secrets and variables** → **Actions**
3. Locate `WINDOWS_ADMIN_PASSWORD`
4. Copy the value (repository admin access required)

Username defaults to `azureuser` unless overridden by `admin_username`.

---

## Step 3: Get Jumpbox Details

```bash
RESOURCE_GROUP="azlz-rg"  # change as needed

echo "=== Windows Jumpbox (azlz-jumpbox-win-vm) ==="
az vm show --name azlz-jumpbox-win-vm --resource-group $RESOURCE_GROUP \
  --query "{name: name, provisioningState: provisioningState}" -o table

WINDOWS_PRIVATE_IP=$(az vm list-ip-addresses --name azlz-jumpbox-win-vm \
  --resource-group $RESOURCE_GROUP --query "[0].virtualMachine.network.privateIpAddresses[0]" -o tsv)

echo "Windows Jumpbox Private IP: $WINDOWS_PRIVATE_IP"
```

---

## Step 4: Connect Through Azure Bastion

1. Open Azure Portal and go to your Bastion resource
2. Click **Connect**
3. Select VM: `azlz-jumpbox-win-vm`
4. Connection type: **RDP**
5. Username: `azureuser` (or your configured admin username)
6. Password: value from `WINDOWS_ADMIN_PASSWORD`
7. Click **Connect**

---

## Step 5: Validate Private Access from Jumpbox

From the Windows jumpbox PowerShell:

```powershell
az login
az account show

# Check basic network reachability
Test-NetConnection -ComputerName <private-endpoint-ip-or-fqdn> -Port 443
```

---

## Step 6: Troubleshooting

### Bastion connection fails

```bash
az bastion show --name azlz-bastion --resource-group $RESOURCE_GROUP
az network nsg rule list --nsg-name azlz-bastion-nsg --resource-group $RESOURCE_GROUP -o table
```

### VM access fails after Bastion connects

```bash
az vm get-instance-view --name azlz-jumpbox-win-vm --resource-group $RESOURCE_GROUP \
  --query instanceView.statuses -o table

az network nsg rule list --nsg-name azlz-jumpbox-nsg --resource-group $RESOURCE_GROUP -o table
```

### Password issues

- Confirm `WINDOWS_ADMIN_PASSWORD` is current and copied exactly
- Reset password in Azure Portal if needed
- Update GitHub secret after reset

---

## Step 7: Post-Access Hardening

- Rotate the Windows admin password after initial validation
- Update `WINDOWS_ADMIN_PASSWORD` in GitHub Secrets immediately
- Restrict who has rights to view repository secrets
