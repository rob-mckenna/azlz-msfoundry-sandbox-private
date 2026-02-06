# GitHub Actions Workflows

This repository includes automated GitHub Actions workflows for building, testing, and deploying the Azure Landing Zone across three environments: **DEV**, **QA**, and **PROD**.

## Workflows Overview

### 1. **CI/CD Pipeline** (`ci-cd.yml`)

Automated build, test, and deployment pipeline triggered by code changes.

**Triggers:**
- `main` branch push → Auto-deploy to **PROD** (requires approval)
- `qa` branch push → Auto-deploy to **QA**
- `develop` branch push → Auto-deploy to **DEV**
- Manual trigger with environment selection

**Steps:**
1. ✅ Checkout code
2. ✅ Build .NET application (Release mode)
3. ✅ Run unit tests
4. ✅ Build Docker image
5. ✅ Push to Azure Container Registry (private)
6. ✅ Deploy to Container Apps
7. ✅ Health check (verify application is running)

**Artifacts:**
- Docker image (stored in private ACR)
- Test results (attached to workflow run)

**Environment-Specific Behavior:**
- **DEV**: Auto-deploys on develop branch, allows failures to continue
- **QA**: Auto-deploys on qa branch, stricter validation
- **PROD**: Requires manual approval before deployment, protects from accidental pushes

### 2. **Infrastructure Deployment** (`deploy-infrastructure.yml`)

Manual Terraform workflow for managing cloud infrastructure changes.

**Triggers:**
- Manual trigger (workflow_dispatch) only
- Select environment: dev, qa, or prod
- Select action: plan, apply, or destroy

**Steps:**
1. 🔐 Azure authentication
2. ✅ Terraform format check
3. ✅ Terraform init
4. ✅ Terraform validate
5. ✅ Terraform plan (always shows changes first)
6. ✅ Terraform apply or destroy (manual confirmation)
7. 📊 Capture outputs for reference

**Usage:**
- **Plan only**: Review infrastructure changes without applying
- **Apply**: Deploy new/modified resources
- **Destroy**: Remove all infrastructure (DESTRUCTIVE - use carefully)

**Protection:**
- PROD requires approval before apply/destroy
- Always see plan before applying
- Full audit trail in GitHub Actions logs

### 3. **Tests** (`test.yml`)

Continuous testing and code quality checks.

**Triggers:**
- Push to main/develop/qa (files changed: src/**, Dockerfile, workflow)
- Pull requests targeting main/develop
- Manual trigger anytime

**Steps:**
1. ✅ Restore .NET dependencies
2. ✅ Build application (Release mode)
3. ✅ Run unit tests (xUnit, NUnit, etc.)
4. ✅ Code style analysis
5. ✅ Security vulnerability scan
6. ✅ Dockerfile linting

**Outputs:**
- Test results report
- Code coverage (if configured)
- Build artifacts for inspection

## Setup Instructions

### Prerequisites

1. **GitHub Environments** created (Settings → Environments):
   - `dev`
   - `qa`
   - `prod` (with approval requirement)

2. **Azure Service Principals** for each environment:
   - Service Principal with Contributor role
   - JSON credentials stored as GitHub secrets

3. **Terraform State Backend** setup in Azure Storage

4. **GitHub Secrets** configured per environment

**Detailed setup:** See [WORKFLOWS-SETUP.md](.github/WORKFLOWS-SETUP.md)

## Running Workflows

### Automatic Triggers

**Just push code to trigger:**

```bash
# Deploy to DEV
git checkout develop
git commit -m "New feature"
git push origin develop  # Auto-triggers CI/CD → builds, tests, deploys to DEV

# Deploy to QA
git checkout qa
git rebase develop
git push origin qa  # Auto-triggers CI/CD → builds, tests, deploys to QA

# Deploy to PROD
git checkout main
git rebase qa
git push origin main  # CI/CD triggers → requires approval → deploys to PROD
```

### Manual Triggers

**In GitHub UI:**

1. **Deploy Application:**
   - Go to **Actions** tab
   - Click **Build, Test & Deploy**
   - Click **Run workflow**
   - Choose environment from dropdown
   - Click green **Run workflow** button

2. **Deploy Infrastructure:**
   - Go to **Actions** tab
   - Click **Deploy Infrastructure (Terraform)**
   - Click **Run workflow**
   - Choose environment and action (plan/apply/destroy)
   - Click green **Run workflow** button

3. **Run Tests:**
   - Go to **Actions** tab
   - Click **Test**
   - Click **Run workflow** button

**Via GitHub CLI:**

```bash
# Deploy application to DEV
gh workflow run ci-cd.yml --ref develop

# Plan infrastructure for QA
gh workflow run deploy-infrastructure.yml \
  -f environment=qa \
  -f action=plan

# Apply infrastructure to PROD (requires approval)
gh workflow run deploy-infrastructure.yml \
  -f environment=prod \
  -f action=apply
```

## Monitoring Deployments

### Real-Time Monitoring

1. Go to **Actions** tab
2. Click running workflow
3. Watch logs as each step executes
4. Expandable sections for each step's logs

### Post-Deployment

1. **Deployments tab**: View history of all deployments with status
2. **Environments tab**: Current deployment status per environment
3. **Checks**: Code coverage reports, test results

### Notifications

GitHub can send notifications for:
- Workflow completion
- Approval requests (PROD)
- Workflow failures

Configure in **Settings → Notifications**

## Environment Promotion Workflow

This is the recommended pattern for safe deployments:

```
Feature Development
       ↓
git commit → git push develop
       ↓ (auto-triggers)
CI/CD: Build, Test, Deploy to DEV
       ✓ (all tests pass)
       ↓
Code Review (Pull Request)
       ↓ (after approval)
git commit → git push qa
       ↓ (auto-triggers)
CI/CD: Build, Test, Deploy to QA
       ✓ (QA validation passes)
       ↓
Release Approval (Pull Request)
       ↓ (after approval)
git commit → git push main
       ↓ (auto-triggers)
CI/CD: Build, Test, Ready to Deploy to PROD
       ⬜ (awaits approval - manual confirm)
       ↓
GitHub Approves
       ↓
CI/CD: Deploy to PROD
       ✓
       ↓
Production Live
```

## Secrets and Credentials

### Stored Secrets

All sensitive data is stored as GitHub Secrets, not in code:

- Azure credentials (service principals)
- ACR login credentials
- Terraform state backend credentials
- SSH keys (indirectly)

### Accessing Secrets in Workflows

```yaml
uses: azure/login@v1
with:
  creds: ${{ secrets.DEV_AZURE_CREDENTIALS }}
```

**Security:** GitHub automatically masks secret values in logs - they're never visible.

## Advanced Usage

### Deploy to Multiple Regions

Extend workflows to support region selection:

```yaml
strategy:
  matrix:
    region: [eastus, westus]
```

### Deploy to Multiple Subscriptions

Use different service principals per subscription:

```yaml
- uses: azure/login@v1
  with:
    creds: ${{ secrets[format('{0}_{1}_CREDENTIALS', 
      matrix.environment, 
      matrix.region)] }}
```

### Skip Deployments

Add `[skip ci]` to commit message to skip workflows:

```bash
git commit -m "Documentation update [skip ci]"
```

### Terraform Workspaces

Use Terraform workspaces for multi-environment state:

```bash
terraform workspace select dev
terraform apply -var-file=variables.tfvars
```

## Troubleshooting

### Workflow Fails at Azure Login

```
Error: Error: 'AZURE_CREDENTIALS' not found in the action environment.
```

**Solution:** Verify `{ENV}_AZURE_CREDENTIALS` secret exists and is valid

### Container App Deployment Fails

```
Error: ACR pull failed - image not found
```

**Solution:** 
- Verify image was pushed to ACR (check build log)
- Verify image name matches (`azlz-app:{sha}`)
- Check managed identity has AcrPull role

### Terraform Plan Shows Unexpected Changes

**Solution:** 
- Run `terraform plan` manually to verify state
- Check for infrastructure drift
- Review pending resource changes

### Health Check Timeout

Application not responding to `/health` in 30 seconds

**Solution:**
- Application still starting (normal for first deploy)
- Check Container App logs in Azure Portal
- Increase timeout in workflow if needed
- Verify health endpoint is implemented

### PROD Approval Stuck

**Solution:**
- Check environment protection rules in Settings
- Verify reviewer has permission to approve
- Comment on deployment to re-trigger approvers

## Best Practices

### Code Review

✅ Always use Pull Requests for changes to main/qa branches  
✅ Require at least 1 reviewer before merge  
✅ Use GitHub branch protections to enforce  

### Testing

✅ Test in DEV first (`develop` branch)  
✅ Validate in QA before PROD (`qa` branch)  
✅ Run full test suite in CI pipeline  

### Deployments

✅ Always review Terraform plan before apply  
✅ Use approvals for PROD (enabled by default)  
✅ Monitor health checks after deployment  

### Secrets

✅ Rotate service principal credentials regularly  
✅ Never commit secrets to repository  
✅ Use GitHub Secrets for all sensitive data  
✅ Audit GitHub Actions logs for secret exposure  

### Infrastructure

✅ Version control all infrastructure (Terraform)  
✅ Use separate backends per environment  
✅ Tag resources with environment labels  
✅ Enable audit logging for all changes  

## Common Commands Reference

```bash
# Trigger DEV deployment
git push origin develop

# Trigger QA deployment
git push origin qa

# Trigger PROD deployment (requires approval)
git push origin main

# Check workflow status
gh run list

# View specific run logs
gh run view RUN_ID --log

# Approve workflow waiting on review
gh run approve RUN_ID

# Re-run failed workflow
gh run rerun RUN_ID

# View environment deployments
gh deployment list --environment prod
```

## Related Documentation

- [WORKFLOWS-SETUP.md](.github/WORKFLOWS-SETUP.md) - Detailed setup instructions
- [README.md](../README.md) - Main project documentation
- [CI-CD-RUNNER.md](../CI-CD-RUNNER.md) - Self-hosted runner setup
- [TERRAFORM.md](../TERRAFORM.md) - Infrastructure as Code guide

## Support

For workflow issues:
1. Check workflow logs in **Actions** tab
2. Review error messages and suggested fixes
3. Check [WORKFLOWS-SETUP.md](.github/WORKFLOWS-SETUP.md) troubleshooting section
4. Verify all secrets and environment variables are configured
5. Test locally with `terraform plan` or `dotnet test` before pushing

---

**Last Updated:** February 5, 2026  
**Workflows Version:** 1.0  
**Created by:** GitHub Actions Setup
