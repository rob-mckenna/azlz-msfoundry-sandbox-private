# GitHub Actions Self-Hosted Runner Setup

## Overview

This Azure Landing Zone includes an **optional** self-hosted GitHub Actions runner deployed as a **Container Apps Job** inside your secure VNet. This allows you to run CI/CD workflows inside Azure without exposing runners to the internet.

## Architecture

```
GitHub Repository
    ↓
GitHub Actions Workflow (uses: self-hosted label)
    ↓
Runner Registration Token (GITHUB_TOKEN)
    ↓
Azure Container Apps Job
    ├── Subnet: 10.0.6.0/24 (CI/CD isolated subnet)
    ├── Identity: User-assigned managed identity
    ├── Permissions: ACR Pull via RBAC
    └── Networking: Internal only (no public IP)
    ↓
Azure Container Registry (Private)
    ↓
Build artifacts stored privately
```

## Prerequisites

1. **GitHub Account** with repository access
2. **Organization/Repository Permissions** to create self-hosted runners:
   - Personal repo: You own it
   - Organization repo: Admin or Org owner permissions

2. **GitHub PAT or Registration Token**:
   - Navigate to: `GitHub → Settings → Actions → Runners`
   - Click "New self-hosted runner"
   - Copy the **registration token** (starts with `AAAA...`)

## Setup Instructions

### Step 1: Get GitHub Runner Token

1. Go to your GitHub repository (or organization)
2. Settings → Actions → Runners → "New self-hosted runner"
3. Copy the **registration token** (valid for ~1 hour)
   ```
   AAAA...
   ```

### Step 2: Update Terraform Configuration

Edit `infrastructure/terraform/terraform.tfvars`:

```hcl
# Enable the GitHub Actions runner
enable_cicd_runner = true

# Paste your GitHub registration token (from Step 1)
github_runner_registration_token = "AAAA..."

# Your GitHub repository URL
github_runner_url = "https://github.com/your-org/your-repo"

# Container image with GitHub Actions runner pre-installed
# Default: ghcr.io/myoats/actions-runner:latest
runner_container_image = "ghcr.io/myoats/actions-runner:latest"
```

### Step 3: Deploy Infrastructure

```bash
cd infrastructure/terraform

# Initialize (if not already done)
terraform init

# Plan the deployment
terraform plan

# Apply the changes
terraform apply
```

This creates:
- CI/CD subnet (10.0.6.0/24)
- CI/CD NSG with outbound HTTPS (443) and internal communication
- Container Apps environment (separate from main ACA environment)
- User-assigned managed identity with ACR pull permission
- Container Apps Job with GitHub runner

### Step 4: Verify Runner Registration

The runner will automatically register with GitHub (takes 1-2 minutes):

1. Go to your GitHub repo: **Settings → Actions → Runners**
2. Look for `azlz-github-runner` in the list
3. Status should be **"Idle"** when ready

## Using the Runner in GitHub Actions

### Example Workflow

Create `.github/workflows/ci-cd.yml`:

```yaml
name: Build with Self-Hosted Runner

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: self-hosted  # Uses your custom runner
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Build .NET app
        run: |
          cd src/webapp
          dotnet build -c Release
      
      - name: Login to ACR
        uses: azure/docker-login@v1
        with:
          login-server: ${{ secrets.REGISTRY_LOGIN_SERVER }}
          username: ${{ secrets.REGISTRY_USERNAME }}
          password: ${{ secrets.REGISTRY_PASSWORD }}
      
      - name: Build and push Docker image
        run: |
          docker build -t ${{ secrets.REGISTRY_LOGIN_SERVER }}/azlz-app:${{ github.sha }} .
          docker push ${{ secrets.REGISTRY_LOGIN_SERVER }}/azlz-app:${{ github.sha }}
```

### Key Points

- **runs-on**: Use `self-hosted` to use your custom runner
- **ACR Access**: The runner has managed identity with ACR pull/push permissions
- **Network Access**: Can communicate with:
  - Private ACR (via private endpoint)
  - Private Container Apps (via internal load balancer)
  - Azure SQL, Cosmos DB (via service endpoints)
- **Isolation**: Runs inside VNet, no internet exposure for artifacts

## Network Security

The CI/CD runner is protected by:

1. **Dedicated Subnet**: Isolated in 10.0.6.0/24
2. **NSG Rules**:
   - ✅ Outbound HTTPS (443) to GitHub APIs
   - ✅ Outbound to internal resources (VNet communication)
   - ❌ No inbound from internet
   - ❌ No public IP address

3. **Identity**: User-assigned managed identity with minimal permissions
   - ACR Pull: Pull images from private registry
   - No VM/Bastion access

## Disabling the Runner

To temporarily disable the runner without deleting it:

1. Set in `terraform.tfvars`:
   ```hcl
   enable_cicd_runner = false
   ```

2. Apply changes:
   ```bash
   terraform apply
   ```

3. The runner will be deleted from Azure (but remains registered in GitHub)
4. Go to GitHub Settings → Actions → Runners and remove the offline runner

## Container Image Requirements

The `runner_container_image` must include:
- GitHub Actions runner pre-installed
- All dependencies needed for your CI/CD jobs (dotnet, docker, etc.)
- Can be based on `ghcr.io/actions/runner:latest`

Example Dockerfile:
```dockerfile
FROM ghcr.io/actions/runner:latest

# Add any additional tools
RUN apt-get update && apt-get install -y \
    dotnet-sdk-10.0 \
    docker.io \
    && rm -rf /var/lib/apt/lists/*
```

## Troubleshooting

### Runner doesn't appear in GitHub
- Check registration token is valid (they expire)
- Verify `enable_cicd_runner = true` in terraform.tfvars
- Run `terraform apply` again
- Check Azure Portal: Container Apps → azlz-cicd-app-env → Jobs → azlz-github-runner

### ACR push fails
- Verify managed identity has AcrPush role (current default is AcrPull)
- Check runner container image has docker/podman installed
- Verify ACR name in workflow matches Terraform output

### Slower builds
- Runner is in Consumption tier - may have cold start delays
- Consider Container Apps Premium workload profile for consistent performance
- Add caching to GitHub workflow for faster builds

### Removing the runner
```bash
# Set to false in terraform.tfvars
enable_cicd_runner = false

# Apply
terraform apply

# Go to GitHub to remove offline runner from settings
```

## Security Best Practices

1. **Token Rotation**: GitHub runner tokens expire after use
2. **Secrets Management**: Use GitHub Secrets, not environment variables
3. **ACR Permissions**: Limit to AcrPull unless push needed
4. **Logging**: Monitor container app logs in Log Analytics
5. **Network**: No direct internet access - artifacts stay private

## Cost Considerations

- **Container Apps Job**: Consumption tier, pay-per-execution
- **Storage**: Logs retained in Log Analytics (30 days)
- **Bandwidth**: Internal communication (VNet) is free
- **ACR**: Included in Registry costs

Typical cost: $10-30/month for low-frequency builds

## Further Reading

- [GitHub Actions - Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners)
- [Azure Container Apps Jobs](https://learn.microsoft.com/azure/container-apps/jobs)
- [GitHub Actions Runner Docker](https://github.com/actions/runner)
