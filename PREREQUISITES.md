# Prerequisites Checklist

Before deploying the Azure Landing Zone, validate that you have all required permissions, tools, and access. This checklist helps identify any blockers early.

**Estimated Time to Complete**: 15-20 minutes

---

## 1. Azure Subscription Prerequisites

### Required Permissions
- [ ] **Subscription Owner** or **Contributor** role assigned to your Azure user account
  - To verify: `az role assignment list --output table`
  
- [ ] Able to **create Service Principals** (checked via Azure CLI)
  ```bash
  az ad sp list --all --query "length(@)"
  # If this works without error, you can create service principals
  ```

- [ ] Able to **create Resource Groups**
  ```bash
  # You should be able to run this successfully
  az group create --name azlz-test-rg --location eastus
  # Then delete it: az group delete --name azlz-test-rg --yes
  ```

- [ ] Able to **assign IAM roles** to service principals
  - This is needed to give GitHub Actions permissions

- [ ] Able to **create Storage Accounts** (for Terraform state backend)

### Required Quotas & Limits
- [ ] **Compute quota**: At least 4 vCPUs available (2x jumpbox VMs)
  - Check: https://portal.azure.com → Subscriptions → Usage + quotas
  - Look for "Standard DSv5 Family vCPU" or similar

- [ ] **Public IP quota**: At least 4 available
  - Needed for: 2x Jumpbox IPs + Bastion IP + optional others

- [ ] **Virtual Network quota**: At least 1 available

- [ ] **Spending limit**: Not exceeded or not enforced
  - Check: https://portal.azure.com → Subscriptions → Spending limit
  - Disable if it might block resource creation

- [ ] **Subscription status**: Active and not in trial/suspended state

### Recommended but Optional
- [ ] Separate subscription for dev/test (avoid impacting prod infrastructure)
- [ ] Naming conventions documented for your organization
- [ ] Tagging strategy defined

---

## 2. GitHub Prerequisites

### Required Permissions
- [ ] **Repository Admin** access (to manage settings, secrets, environments)
  - For your organization: Organization Owner or Repository Admin
  - For personal account: Default (you own it)

- [ ] Able to **create Environments** (dev, qa, prod)
  - Settings → Environments → New environment

- [ ] Able to **manage Secrets and variables**
  - Settings → Secrets and variables → Actions (both Repository and Environment secrets)

- [ ] Able to **enable Branch protection rules** (for prod approvals)
  - Settings → Branches → Branch protection rules

- [ ] **GitHub Actions** enabled on repository
  - Settings → Actions → General → "Allow all actions and reusable workflows"

### GitHub Account Requirements
- [ ] GitHub account created (free or paid tier)
- [ ] GitHub organization set up (if multi-team deployment)
- [ ] Access to create repositories in your organization

### GitHub Actions Quota
- [ ] Check your Actions usage quota
  - Free tier: 2,000 minutes/month (sufficient for this project)
  - Paid tier: Included with plan
  - https://github.com/settings/billing/actions

### Optional
- [ ] Two-factor authentication (2FA) enabled on GitHub account
- [ ] Approval workflow defined for production deployments

---

## 3. Local Machine Prerequisites

### Required Tools

#### Azure CLI
```bash
# Check if installed
az --version

# Should output version 2.40.0 or higher
# If not installed: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
```

- [ ] **Azure CLI 2.40+** installed
  - Windows: https://aka.ms/installazurecliwindows
  - Mac: `brew install azure-cli`
  - Linux: Follow platform-specific instructions

#### Terraform
```bash
# Check if installed
terraform --version

# Should output version 1.5.0 or higher
# If not installed: https://www.terraform.io/downloads.html
```

- [ ] **Terraform 1.5+** installed
  - Windows: `choco install terraform` or download from terraform.io
  - Mac: `brew install terraform`
  - Linux: Download from terraform.io

#### Git
```bash
# Check if installed
git --version

# Should output version 2.30+
```

- [ ] **Git 2.30+** installed
  - Windows: https://git-scm.com/download/win
  - Mac: `brew install git`
  - Linux: `sudo apt install git` (Ubuntu/Debian)

#### SSH Key Generation (Built-in)
```bash
# Test SSH key generation (should exist on all platforms)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/test-key -N ""

# Verify: ls -la ~/.ssh/test-key*
# Then delete test keys: rm ~/.ssh/test-key*
```

- [ ] **SSH key generator** available (built-in on all platforms)

### Recommended Tools (Optional)

#### Docker (if building images locally)
```bash
docker --version
# Should output version 20.10+
```

- [ ] **Docker 20.10+** (optional - only if building images locally)

#### .NET SDK 8.0 (if testing webapp locally)
```bash
dotnet --version
# Should output version 8.0+
```

- [ ] **.NET SDK 8.0+** (optional - only if modifying webapp code)

#### jq (if parsing JSON in scripts)
```bash
jq --version
```

- [ ] **jq** (optional - helpful for CLI scripts)

---

## 4. Access & Connectivity

### Network Access
- [ ] Can access **https://github.com** (not blocked by firewall)
- [ ] Can access **https://portal.azure.com** (not blocked by firewall)
- [ ] Can reach **Azure APIs** (api.github.com, management.azure.com)
- [ ] Can download Docker images (if building locally)

### Authentication Test
```bash
# Verify Azure CLI authentication
az login

# Verify GitHub API access (if using GitHub CLI)
gh auth status
```

- [ ] Successfully authenticated to **Azure CLI** (`az login`)
- [ ] Can reach **GitHub** (via GitHub CLI or web browser)

---

## 5. Azure CLI Validation

Run these commands to confirm your setup:

```bash
# 1. Show current subscription
az account show --output table

# 2. List resource groups (confirms permissions)
az group list --output table

# 3. Verify you can create service principals
az ad sp list --all --query "length(@)"

# 4. Check terraform (via Azure CLI)
az terraform version
# Or native terraform
terraform version

# 5. Check git
git --version
```

**All commands above should complete without errors.**

---

## 6. Role and Permission Validation

### Azure Subscription Roles
```bash
# Check your roles on current subscription
az role assignment list \
  --assignee $(az account show --query user.name -o tsv) \
  --output table

# Should show "Contributor" or "Owner" for current subscription
```

- [ ] Have **Contributor** or **Owner** role on Azure subscription
  - ❌ **Blocker**: If you only have "Reader" or "Virtual Machine Contributor"

### GitHub Repository Permissions
- [ ] Can create repositories (or have access to existing repo)
- [ ] Can manage organization/team settings (if applicable)
- [ ] Can create branch protection rules

---

## 7. Quotas Verification

### Check Azure Quotas
```bash
# Check vCPU quota for compute
az compute vm list-usage --location eastus --output table
# Look for "Standard DSv5 Family vCPU" or similar

# Check public IP quota
az network public-ip list-usage --location eastus --output table
```

**Required Quotas:**
- [ ] **vCPU quota**: ≥ 4 (for 2 jumpbox VMs: 2x D4s_v5 = 4 vCPUs)
- [ ] **Public IPs**: ≥ 4 (jumpbox Linux, jumpbox Windows, Bastion, optional)
- [ ] **Virtual Networks**: ≥ 1
- [ ] **Storage Accounts**: ≥ 1 (for Terraform state)

### Check Spending Limit
```bash
# Via Azure Portal: Subscriptions → Your Subscription → Spending limit
# Or ask your IT admin if limit is enforced
```

- [ ] **Spending limit** is disabled OR high enough for test deployment
  - Default deployment cost: ~$1,377/month (DEV environment in East US)
  - See [cost estimation](INDEX.md#cost-estimation) for full details by region

---

## 8. Security & Compliance Checklist

- [ ] Understand that **SSH private keys** will never be committed to Git
- [ ] Understand that **GitHub Secrets** are used for sensitive data
- [ ] Understand that **Terraform state** will be stored in Azure Storage
- [ ] Understand that **service principals** will have Contributor permissions to subscription
- [ ] Comfortable with **approval process for PROD** deployments

## 9. Credentials & Access Preparation

### Jumpbox VM Credentials

Both Linux and Windows jumpbox VMs will be provisioned with credentials:

#### Linux Jumpbox
- [ ] **SSH key pair** prepared locally
  ```bash
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/azlz-jumpbox -N ""
  ```
- [ ] SSH public key stored in **GitHub Secret**: `SSH_PUBLIC_KEY`
- [ ] SSH private key kept secure (never committed or shared)
- [ ] Username: `azureuser` (from `admin_username` variable)

#### Windows Jumpbox
- [ ] **Strong password prepared** for Windows admin user
  - Requirements: 12-123 characters, must include:
    - ✓ Uppercase letters (A-Z)
    - ✓ Lowercase letters (a-z)
    - ✓ Numbers (0-9)
    - ✓ Special characters (!@#$%^&*)
  - Example: `MyP@ssw0rd2026!`
- [ ] Password stored in **GitHub Secret**: `WINDOWS_ADMIN_PASSWORD`
- [ ] Username: `azureuser` (from `admin_username` variable)
- [ ] Access method: Azure Bastion → RDP protocol

### Post-Deployment Credentials

- [ ] Understand credentials are **only stored in GitHub Secrets**
- [ ] Credentials are **NOT stored in Terraform state** or code
- [ ] To retrieve credentials after deployment:
  1. Go to GitHub repository
  2. Settings → Secrets and variables → Actions
  3. View secrets (GitHub admin access required)
- [ ] Plan for **credential rotation** policy
- [ ] Document who has access to retrieve credentials

### Access Method: Azure Bastion

- [ ] Understand **no direct SSH/RDP access** to jumpbox VMs
- [ ] All access goes through **Azure Bastion** service
- [ ] Bastion provides secure, browser-based remote access
- [ ] Credentials (SSH key or password) used only within Bastion tunnel

---

## 9. Documentation Review

Before starting, read these in order:

1. [ ] **README.md** - Architecture overview
2. [ ] **GITHUB-ACTIONS-QUICKSTART.md** - 10-minute setup guide
3. [ ] **DEPLOYMENT-CHECKLIST.md** - Step-by-step deployment
4. [ ] **ARCHITECTURE.md** - Deep dive into design decisions

---

## 10. Final Validation

Run this complete validation script:

```bash
#!/bin/bash

echo "=== Azure Landing Zone Prerequisites Validation ==="
echo ""

# 1. Azure CLI
echo "1. Checking Azure CLI..."
az --version > /dev/null 2>&1 && echo "   ✓ Azure CLI installed" || echo "   ✗ Azure CLI not found"

# 2. Terraform
echo "2. Checking Terraform..."
terraform --version > /dev/null 2>&1 && echo "   ✓ Terraform installed" || echo "   ✗ Terraform not found"

# 3. Git
echo "3. Checking Git..."
git --version > /dev/null 2>&1 && echo "   ✓ Git installed" || echo "   ✗ Git not found"

# 4. SSH key generation
echo "4. Checking SSH key generation..."
ssh-keygen -t rsa -b 4096 -f ~/.ssh/test-prereq -N "" > /dev/null 2>&1
if [ -f ~/.ssh/test-prereq ]; then
    rm ~/.ssh/test-prereq ~/.ssh/test-prereq.pub
    echo "   ✓ SSH key generation works"
else
    echo "   ✗ SSH key generation failed"
fi

# 5. Azure authentication
echo "5. Checking Azure authentication..."
az account show > /dev/null 2>&1 && echo "   ✓ Authenticated to Azure" || echo "   ✗ Not authenticated (run: az login)"

# 6. Azure subscription access
echo "6. Checking Azure subscription access..."
az group list > /dev/null 2>&1 && echo "   ✓ Can access resource groups" || echo "   ✗ Cannot access resource groups"

echo ""
echo "=== Validation Complete ==="
```

Save as `validate-prerequisites.sh`, then run:
```bash
chmod +x validate-prerequisites.sh
./validate-prerequisites.sh
```

---

## Blockers to Resolve

If you see ✗ marks above, **STOP** and resolve these before proceeding:

### Critical Blockers (Must Resolve)
- ❌ **Do not have Contributor role** → Contact subscription admin for role assignment
- ❌ **Cannot create service principals** → Contact subscription admin
- ❌ **Terraform version < 1.5** → Upgrade Terraform
- ❌ **Azure CLI not installed** → Install from microsoft.com
- ❌ **Cannot authenticate to Azure** → Run `az login` and sign in
- ❌ **Spending limit blocking resources** → Disable or increase limit

### Network/Access Blockers
- ❌ **Cannot reach github.com** → Check firewall rules
- ❌ **Cannot reach portal.azure.com** → Check firewall rules
- ❌ **Cannot download container images** → Check firewall/proxy settings

---

## What to Do After Validation

Once all checkboxes are ✓:

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd azlz-msfoundry-sandbox-private
   ```

2. **Follow GITHUB-ACTIONS-QUICKSTART.md**
   - Set up GitHub Environments
   - Create Azure Service Principals
   - Configure GitHub Secrets
   - Deploy infrastructure

3. **Expected Setup Time**: 30-45 minutes (after validation)

---

## Support

If you encounter issues during prerequisites validation:

1. Check the **DEPLOYMENT-CHECKLIST.md** for detailed troubleshooting
2. Review **ARCHITECTURE.md** for design decisions
3. Contact: [Your support contact]

---

## Prerequisite Summary Table

| Component | Required Version | Check Command | Status |
|-----------|-----------------|---------------|--------|
| Azure CLI | 2.40+ | `az --version` | ☐ |
| Terraform | 1.5+ | `terraform --version` | ☐ |
| Git | 2.30+ | `git --version` | ☐ |
| Docker | 20.10+ (optional) | `docker --version` | ☐ |
| .NET SDK | 10.0+ (optional) | `dotnet --version` | ☐ |
| Azure Subscription | Contributor+ | `az role assignment list` | ☐ |
| GitHub Access | Admin role | GitHub UI | ☐ |
| vCPU Quota | ≥ 4 | Azure Portal | ☐ |
| Public IP Quota | ≥ 4 | Azure Portal | ☐ |

---

**Last Updated**: February 6, 2026  
**Document Version**: 1.0
