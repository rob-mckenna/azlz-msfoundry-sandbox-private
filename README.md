# Azure Landing Zone - Lightweight Foundation

A comprehensive, lightweight Azure Landing Zone implementation featuring virtual networks, container orchestration, and secure access patterns.

> **📋 Before You Start**: Please review [PREREQUISITES.md](PREREQUISITES.md) to ensure you have all required permissions, tools, and access before beginning deployment.

## Architecture Overview

```
┌───────────────────────────────────────────────────────────────┐
│                     Azure Landing Zone                        │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │            Virtual Network (10.0.0.0/16)                │  │
│  ├─────────────────────────────────────────────────────────┤  │
│  │                                                         │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────────┐ │  │
│  │  │ ACR Subnet   │  │ ACA Subnet   │  │Jumpbox Subnet  │ │  │
│  │  │(10.0.1.0/24) │  │(10.0.2.0/24) │  │(10.0.3.0/24)   │ │  │
│  │  │              │  │              │  │                │ │  │
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌────────────┐ │ │  │
│  │  │ │Container │ │  │ │Container │ │  │ │  Jumpbox   │ │ │  │
│  │  │ │Registry  │ │  │ │Apps Env  │ │  │ │ Windows VM │ │ │  │
│  │  │ │          │ │  │ │          │ │  │ └────────────┘ │ │  │
│  │  │ │ Premium  │ │  │ │Container │ │  │ │              │ │  │
│  │  │ │   SKU    │ │  │ │App       │ │  │ │              │ │  │
│  │  │ │+ Private │ │  │ │+ Internal│ │  │ │              │ │  │
│  │  │ │ Endpoint │ │  │ │   LB     │ │  │ │              │ │  │
│  │  │ └──────────┘ │  │ └──────────┘ │  │ Public IPs     │ │  │
│  │  └──────────────┘  └──────────────┘  └────────────────┘ │  │
│  │                                                         │  │
│  │  ┌──────────────────────────────────────────────────┐   │  │
│  │  │         Bastion Subnet (10.0.4.0/24)             │   │  │
│  │  │  ┌──────────────────────────────────────────┐    │   │  │
│  │  │  │      Azure Bastion (Basic)               │    │   │  │
│  │  │  │   (Secure Remote Access)                 │    │   │  │
│  │  │  └──────────────────────────────────────────┘    │   │  │
│  │  └──────────────────────────────────────────────────┘   │  │
│  │                                                         │  │
│  │  ┌──────────────────────────────────────────────────┐   │  │
│  │  │         APIM Subnet (10.0.5.0/24)                │   │  │
│  │  │  ┌──────────────────────────────────────────┐    │   │  │
│  │  │  │   API Management (StandardV2)            │    │   │  │
│  │  │  │   Internal VNet + Private Endpoint       │    │   │  │
│  │  │  └──────────────────────────────────────────┘    │   │  │
│  │  └──────────────────────────────────────────────────┘   │  │
│  │                                                         │  │
│  │  ┌──────────────────────────────────────────────────┐   │  │
│  │  │         Foundry Subnet (10.0.7.0/24)             │   │  │
│  │  │  ┌──────────────────────────────────────────┐    │   │  │
│  │  │  │ Microsoft Foundry AIServices Account     │    │   │  │
│  │  │  │ + Foundry Project (Private Endpoint)     │    │   │  │
│  │  │  └──────────────────────────────────────────┘    │   │  │
│  │  └──────────────────────────────────────────────────┘   │  │
│  │                                                         │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │         Monitoring & Logging                            │  │
│  │         Log Analytics Workspace                         │  │
│  │         (30-day retention)                              │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │         Private Endpoints & DNS                         │  │
│  │         - ACR Private Endpoint                          │  │
│  │         - APIM Private Endpoint                         │  │
│  │         - Foundry Private Endpoint                      │  │
│  │         - Container Apps Internal LB                    │  │
│  │         - Private DNS Zones                             │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

## Components

### 1. **Virtual Network (VNet)**
- **CIDR Block**: 10.0.0.0/16
- **Subnets**:
  - **ACR Subnet** (10.0.1.0/24): Container Registry with private endpoints
  - **ACA Subnet** (10.0.2.0/24): Container Apps with internal load balancer
  - **Jumpbox Subnet** (10.0.3.0/24): Secure administrative access VM
  - **Bastion Subnet** (10.0.4.0/24): Azure Bastion for remote access
  - **APIM Subnet** (10.0.5.0/24): API Management with internal VNet integration
  - **Foundry Subnet** (10.0.7.0/24): Microsoft Foundry private endpoint

### 2. **Azure Container Registry (ACR)**
- **SKU**: Premium (required for private endpoints)
- **Features**:
  - Private endpoint connectivity
  - Public network access disabled
  - Geo-replication ready
  - Admin user disabled by default (use managed identity)
  - Retention policy: 30 days
  - Integrated with Container Apps via managed identity

### 3. **Azure Container Apps (ACA)**
- **Environment**: Managed environment within ACA Subnet
- **Workload Profile**: Consumption (auto-scaling, pay-per-use)
- **Network**: Internal load balancer enabled for private connectivity
- **Private Endpoint**: Internal-only ingress (no external access by default)
- **Private DNS**: Configured for internal resolution
- **Container App**: Pre-configured with:
  - 0.5 CPU, 1 GB memory
  - Auto-scaling (1-5 replicas)
  - Health checks (liveness & readiness probes)
  - Azure Container Registry integration

### 4. **Azure API Management (APIM)**
- **SKU**: StandardV2 (scalable, zone-redundant)
- **Capacity**: 1 unit (configurable)
- **Network**: Internal VNet integration
- **Features**:
  - Private endpoint connectivity
  - Private DNS zone (azure-api.net)
  - Public network access disabled
  - System-assigned managed identity
  - Service endpoints for Storage, SQL, Key Vault

### 5. **Microsoft Foundry**
- **Resource Type**: AI Services account (`AIServices`) with project management enabled
- **Project**: Dedicated Foundry project resource for workload isolation
- **Network**: Public network access disabled when private endpoint is enabled
- **Private Endpoint**: Uses `account` subresource in dedicated Foundry subnet
- **Private DNS**: `privatelink.cognitiveservices.azure.com`, `privatelink.openai.azure.com`, `privatelink.services.ai.azure.com`
- **Access Pattern**: Use existing Bastion + jumpbox for private-network access (no ExpressRoute/VPN gateway required)

### 6. **Jumpbox VM**

#### Windows Jumpbox
- **Image**: Windows Server 2022 Datacenter (Azure Edition)
- **Size**: Standard_D4s_v5 (configurable)
- **Network**: Private IP via Bastion
- **Security**: RDP password-based authentication
- **Use**: Windows-based administrative tasks and tool compatibility

### 7. **Azure Bastion**
- **SKU**: Basic
- **Access**: Secure RDP to jumpbox without public IP exposure
- **Features**: Browser-based console access
- **Network Security**: Properly configured NSGs

### 8. **GitHub Actions CI/CD Automation** (Recommended)
- **Workflows**: Automated build, test, and deploy pipelines
- **Multi-Environment**: Separate workflows for DEV, QA, and PROD
- **Auto-Deployment**: Push code → Automatically deploy to matching environment
- **Infrastructure as Code**: Terraform deployments via GitHub Actions
- **PROD Protection**: Manual approval required before production deployment
- **Setup Guide**: See [GITHUB-ACTIONS-QUICKSTART.md](GITHUB-ACTIONS-QUICKSTART.md)
- **Documentation**: Full details in [.github/workflows/](./.github/workflows/)

### 9. **GitHub Actions Self-Hosted Runner** (Optional)
- **Deployment**: Container Apps Job in dedicated CI/CD environment
- **Subnet**: CI/CD Subnet (10.0.6.0/24) - isolated for CI/CD workloads
- **Features**:
  - Manual trigger Container Apps Job
  - Runs inside VNet for secure artifact handling
  - ACR pull permission via managed identity
  - Configurable via `enable_cicd_runner` feature flag
  - Secrets passed via environment variables
- **Use Case**: GitHub Actions CI/CD without exposed runners
- **Configuration**: Set `enable_cicd_runner = true` and provide `github_runner_url` + `runner_container_image`
- **Setup Guide**: See [CI-CD-RUNNER.md](CI-CD-RUNNER.md)

### 10. **Monitoring & Logging**
- **Log Analytics Workspace**: 30-day retention
- **Integration**: ACA environment logs automatically streamed
- **Diagnostics**: Application and platform metrics

### 11. **Private Endpoints & DNS**
- **ACR Private Endpoint**: In ACR subnet with private DNS (privatelink.azurecr.io)
- **APIM Private Endpoint**: In APIM subnet with private DNS (azure-api.net)
- **Foundry Private Endpoint**: In Foundry subnet with private DNS for AI services/OpenAI/services.ai
- **Container Apps**: Internal load balancer with environment-specific DNS
- **DNS Resolution**: All private DNS zones linked to VNet

## Deployment

### Recommended: GitHub Actions (Automated)
For automated build, test, and deployment across DEV/QA/PROD environments:
- **Setup**: 10 minutes with [GITHUB-ACTIONS-QUICKSTART.md](GITHUB-ACTIONS-QUICKSTART.md)
- **Triggers**: Push to `develop` (DEV) → `qa` (QA) → `main` (PROD, requires approval)
- **Features**: Auto-scales, health checks, approvals for production
- **Full Documentation**: See [.github/workflows/README.md](.github/workflows/README.md)

### Alternative: Manual Terraform & Docker (Step-by-step)
For manual control or learning purposes, follow the Prerequisites and Setup steps below.

### Prerequisites
- Azure CLI (`az` command)
- Terraform (version 1.5 or later)
- Docker (for building container images)
- .NET 8 SDK (for local development)
- Windows admin password (for jumpbox access)
- GitHub account (for automated deployments)

**Security Note**: Provide a strong `windows_admin_password` via secure variables or local, uncommitted tfvars.

### Setup

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd azlz-msfoundry-sandbox-private
   ```

2. **Configure parameters** (optional)
   - Edit `infrastructure/terraform/terraform.tfvars`
  - Adjust location, environment, sizing, and Windows jumpbox settings as needed
  - Set `windows_admin_password` securely (do not commit secrets)

4. **Deploy infrastructure**
   ```bash
   # Make script executable (Linux/Mac)
   chmod +x scripts/tf-deploy.sh
   
   # Deploy
   scripts/tf-deploy.sh
   ```

4. **Build and push container image**
   ```bash
   # Make script executable (Linux/Mac)
   chmod +x scripts/build-and-push.sh
   
   # Build and push to ACR
   scripts/build-and-push.sh <acr-name>
   ```

5. **Update Container App**
   ```bash
   # Make script executable (Linux/Mac)
   chmod +x scripts/update-container-app.sh
   
   # Deploy image to ACA
   scripts/update-container-app.sh <acr-name> azlz-app azlz-rg azlz-app
   ```

6. **Optional: Enable GitHub Actions Self-Hosted Runner**
   
   To deploy a self-hosted GitHub Actions runner inside the VNet:
   
  a. Update `infrastructure/terraform/terraform.tfvars`:
   ```hcl
   enable_cicd_runner               = true
  github_runner_url                = "https://github.com/your-org/your-repo"
  runner_container_image           = "<your-acr>.azurecr.io/github-actions-runner:1.0"
   ```

  b. Run the one-shot deployment script (build image from Microsoft sample source, push to ACR, deploy runner job, verify):
  ```bash
  chmod +x scripts/deploy-github-runner-job.sh
  ACR_NAME=<your-acr-name> \
  GITHUB_REPO=<your-org>/<your-repo> \
  ./scripts/deploy-github-runner-job.sh
  ```

  The script builds from tutorial source:
  `https://github.com/Azure-Samples/container-apps-ci-cd-runner-tutorial.git`
   
   c. Verify runner is registered:
   - Go to GitHub repository → Settings → Actions → Runners
   - Look for the new `azlz-runner` runner (may take 1-2 minutes to appear)
   - Status should be "Idle" when ready

  d. Validate Container Apps Job execution after triggering a workflow that uses `runs-on: self-hosted`:
   ```bash
   az containerapp job execution list \
     --name azlz-runner \
     --resource-group azlz-dev-rg \
     --output table \
     --query '[].{Status:properties.status,Name:name,StartTime:properties.startTime}'
   ```
   
   **Security Notes**:
   - Runner token is passed securely via environment variable
   - Runner executes inside VNet, no internet exposure
   - Built images can be directly pushed to private ACR
   - Runner auto-registers and deregisters with GitHub

## Application

### .NET Web App Features
- **Framework**: .NET 8 Minimal API
- **Health Checks**: `/health` and `/ready` endpoints
- **API Endpoints**:
  - `GET /` - Application info
  - `GET /api/info` - Detailed API information
  - `GET /api/environment` - Environment variables
  - `POST /api/echo` - Echo service

### Building Locally
```bash
cd src/webapp
dotnet restore
dotnet build
dotnet run
```

### Testing the Application

**Note**: With the default configuration (`enable_container_app_external = false`), the Container App is only accessible from within the VNet. You have two options:

**Option 1: Access via Jumpbox** (Recommended for secure environments)
```bash
# Connect to Windows jumpbox via Azure Bastion (RDP), then:
curl http://<container-app-fqdn>/
curl http://<container-app-fqdn>/api/info
```

**Option 2: Enable External Access** (For development/testing)
```bash
# Edit infrastructure/terraform/terraform.tfvars
# Set: enable_container_app_external = true
# Then redeploy: cd infrastructure/terraform && terraform apply
```

**Example commands** (when accessed from within VNet):
```bash
# Get app info
curl http://<container-app-fqdn>/

# Get API info
curl http://<container-app-fqdn>/api/info

# Check environment
curl http://<container-app-fqdn>/api/environment

# Echo test
curl -X POST http://<container-app-fqdn>/api/echo \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello Azure!"}'
```

## Best Practices Implemented

### Network Security
✅ **Network Segmentation**: Separate subnets for each workload  
✅ **Network Security Groups**: Least privilege access rules  
✅ **Service Endpoints**: ACR and KeyVault endpoints on ACR subnet  
✅ **Bastion Access**: No public IPs on VMs  
✅ **Encryption in Transit**: HTTPS-only for ACA ingress  

### Identity & Access
✅ **Managed Identity**: User-assigned identity for ACA  
✅ **ACR Integration**: Passwordless auth via managed identity  
✅ **Single Jumpbox VM**: Windows jumpbox for administrative access  
✅ **RBAC**: Container App managed identity for ACR pull  

### Container & Application
✅ **Non-root User**: Container runs as unprivileged user  
✅ **Health Checks**: Liveness and readiness probes  
✅ **Resource Limits**: Defined CPU/memory constraints  
✅ **Auto-scaling**: Based on HTTP request metrics  
✅ **Minimal API**: Lightweight footprint for container workloads  

### Monitoring & Observability
✅ **Log Analytics**: Integrated workspace for all resources  
✅ **Application Insights Ready**: Can integrate with ACA  
✅ **Diagnostic Logging**: Resource diagnostics configured  
✅ **Health Checks**: Built-in application health monitoring  

### Infrastructure as Code
✅ **Terraform**: Declarative, version-controlled  
✅ **Parameterized**: Easy customization per environment via tfvars  
✅ **Modular**: Organized into provider, main, variables, and outputs files  
✅ **Tagging**: Consistent resource labeling via locals  

### CI/CD & Automation
✅ **GitHub Actions Workflows**: Automated build, test, and deploy pipelines  
✅ **Multi-Environment**: Separate configurations for DEV, QA, and PROD  
✅ **Approval Gates**: Manual approval required for production deployments  
✅ **Infrastructure Automation**: Terraform deployments via GitHub Actions  
✅ **Self-Hosted Runner**: Private CI/CD execution inside VNet (optional)  

### Cost Optimization
✅ **Premium ACR**: Enables private endpoints for security (use Standard for dev/test)  
✅ **Consumption ACA**: Pay-per-use, auto-scales to zero  
✅ **Windows Jumpbox Sizing**: Standard_D4s_v5 for administrative operations  
✅ **Bastion Basic**: Lower cost tier suitable for POC  
✅ **APIM StandardV2**: Scalable tier (use Developer for dev/test)  

## Additional Recommendations for Production

### 1. **Key Management**
- Deploy **Azure Key Vault** for secrets management
- Store database credentials, API keys, connection strings
- Enable soft delete and purge protection

### 2. **Database Layer**
- **Azure Cosmos DB** for globally distributed, scalable data (recommend for AI/chat patterns)
- **Azure SQL Database** for relational workloads
- **Azure Database for PostgreSQL** for open-source preference
- Enable managed identities for authentication

### 3. **API Management**
- Deploy **Azure API Management** for:
  - API gateway and versioning
  - Rate limiting and throttling
  - Policy-based transformation
  - Analytics and monitoring

### 4. **Application Gateway / Load Balancer**
- **Azure Application Gateway** for HTTP(S) load balancing
- WAF (Web Application Firewall) rules
- SSL/TLS termination

### 5. **Storage**
- **Azure Storage Account** for:
  - Blob storage for files/media
  - File shares for persistent storage
  - Queue storage for async messaging
- Enable hierarchical namespace for Data Lake scenarios

### 6. **CI/CD Pipeline**
- **GitHub Actions** or **Azure Pipelines** for:
  - Automated builds
  - Container image builds and pushes
  - Infrastructure deployment
  - Application deployment to ACA

### 7. **Disaster Recovery**
- **Backup & Recovery**: Enable backups for databases
- **Geo-replication**: ACR geo-replication for failover
- **Traffic Manager**: Multi-region failover strategy
- **Backup Policy**: Define RTO/RPO requirements

### 8. **Compliance & Governance**
- **Azure Policy**: Enforce organizational standards
- **Azure Blueprints**: Enforce landing zone standards
- **Audit Logging**: Enable Azure Activity Log retention
- **Compliance**: Implement compliance scanning (via Azure Advisor)

### 9. **DDoS Protection**
- **Azure DDoS Protection Standard** (in production)
- **Web Application Firewall** on Application Gateway

### 10. **Private Connectivity**
- **Private Endpoints**: For ACR, Storage, KeyVault
- **Private Link**: For secure access to PaaS services
- **Service Endpoints**: Already configured for ACR

### 11. **Metrics & Alerting**
- Configure **Azure Monitor** alerts for:
  - ACA replica count and scaling
  - API latency and error rates
  - ACR image vulnerabilities
  - Jumpbox CPU/memory usage
- Create **Action Groups** for notifications

### 12. **Container Image Scanning**
- Enable **ACR image scanning** for vulnerabilities
- Implement **Azure Defender for Containers**
- Automate patching and updates

### 13. **Secrets Management**
- Rotate credentials regularly
- Use **Managed Identity** exclusively (no connection strings in code)
- Store in Key Vault, not environment variables

### 14. **Documentation**
- API documentation (Swagger/OpenAPI)
- Architecture Decision Records (ADRs)
- Runbooks for common operations
- Troubleshooting guides

## File Structure

```
azlz-msfoundry-sandbox-private/
├── infrastructure/
│   └── terraform/
│       ├── provider.tf                # Azure provider configuration
│       ├── versions.tf                # Terraform version requirements
│       ├── main.tf                    # Main infrastructure resources
│       ├── variables.tf               # Variable definitions
│       ├── outputs.tf                 # Output definitions
│       └── terraform.tfvars           # Variable values
├── src/
│   └── webapp/
│       ├── webapp.csproj              # Project file
│       └── Program.cs                 # Minimal API app
├── scripts/
│   ├── tf-deploy.sh                   # Terraform deployment
│   ├── tf-plan.sh                     # Terraform plan
│   ├── tf-destroy.sh                  # Terraform cleanup
│   ├── build-and-push.sh              # Container build & push
│   └── update-container-app.sh        # ACA update script
├── Dockerfile                         # Multi-stage container build
└── README.md                          # This file
```

## Troubleshooting

### Deployment fails with "Invalid VNet configuration"
- Ensure ACA subnet has proper delegation to `Microsoft.App/environments`
- Check subnet CIDR doesn't conflict with existing networks

### Container App won't start
- Check image exists in ACR: `az acr repository show -n <acr-name> --image <image-name>`
- Verify managed identity has AcrPull role on ACR
- Check application logs: `az containerapp logs show -n <app-name> -g <resource-group>`

### Cannot access jumpbox via Bastion
- Verify Bastion public IP is assigned
- Check Network Security Groups allow Bastion → Jumpbox traffic (port 3389)
- Ensure jumpbox has private IP in correct subnet

### Container image build fails
- Verify Docker daemon is running
- Check .NET SDK version: `dotnet --version`
- Ensure Dockerfile path is correct

## Cleanup

To remove all resources:

```bash
# Make script executable (Linux/Mac)
chmod +x scripts/tf-destroy.sh

# Destroy infrastructure
scripts/tf-destroy.sh
```

## Cost Estimation (Monthly)

### Dev Environment (Development/Testing - East US2)

| Component | SKU/Size | Cost |
|-----------|----------|------|
| VNet | - | $0 |
| ACR | Premium | $50 |
| API Management | StandardV2 (1 cap) | $744 |
| ACA (1 replica @ 0.5 CPU) | Consumption | $19 |
| Log Analytics | 30-day retention | $8 |
| Jumpbox VM (Windows) | Standard_D4s_v5 | $186 |
| Azure Bastion | Basic | $377 |
| **Total Dev** | | **~$1,384** |

### Prod Environment (Production Workloads - East US2)

| Component | SKU/Size | Cost |
|-----------|----------|------|
| VNet | - | $0 |
| ACR | Premium | $50 |
| API Management | StandardV2 (1 cap) | $744 |
| ACA (5 replicas @ 0.5 CPU ea) | Consumption | $97 |
| Log Analytics | 30-day retention | $8 |
| Jumpbox VM (Windows) | Standard_D4s_v5 | $186 |
| Azure Bastion | Basic | $377 |
| **Total Prod** | | **~$1,462** |

**Cost Optimization Options:**
- Use ACR Standard ($11/mo) if private endpoints not required
- Use APIM Developer tier ($50/mo) for dev/test environments
- Scale ACA to zero replicas when not in use (serverless)
- Disable Bastion ($377/mo) when not needed or use on-demand pricing
- Use Spot VMs for jumpbox (saves 60-70%, but can be preempted)
- Reserve instances for longer commitments (20-50% savings)

*Note: Pricing as of February 2026. Use [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/) for real-time estimates. This baseline excludes variable Microsoft Foundry model/token usage costs and data egress.*

## License

This project is provided as-is for demonstration and educational purposes.

## Support

For issues, questions, or improvements, please open an issue in the repository or contact the maintainers.
