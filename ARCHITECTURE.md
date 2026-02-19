# Architecture & Best Practices Document

## Infrastructure Architecture

### Network Architecture

#### Subnet Design
```
VNet: 10.0.0.0/16
├── ACR Subnet: 10.0.1.0/24
│   ├── Purpose: Container Registry and artifact storage
│   ├── Features: Private endpoint connectivity
│   ├── Service Endpoints: Microsoft.ContainerRegistry, Microsoft.KeyVault
│   └── NSG: Allows inbound from ACA subnet
│
├── ACA Subnet: 10.0.2.0/24
│   ├── Purpose: Container Apps environment
│   ├── Delegation: Microsoft.App/environments
│   ├── Features: Internal load balancer, private DNS
│   └── NSG: Allows HTTP/HTTPS from internet
│
├── Jumpbox Subnet: 10.0.3.0/24
│   ├── Purpose: Administrative VM for diagnostics
│   ├── Private: No public IP (accessed via Bastion)
│   └── NSG: Only allows RDP from Bastion subnet
│
├── Bastion Subnet: 10.0.4.0/24
│   ├── Purpose: Azure Bastion host
│   ├── Mandatory Name: AzureBastionSubnet
│   └── NSG: Azure-managed rules for gateway access
│
└── APIM Subnet: 10.0.5.0/24
    ├── Purpose: API Management gateway
    ├── Features: Internal VNet integration, private endpoint
    ├── Service Endpoints: Microsoft.Storage, Microsoft.Sql, Microsoft.KeyVault
    └── NSG: APIM-specific rules (3443, 443, 6390)
```

#### Security Boundaries

**Network Segmentation**: Each workload tier is isolated in its own subnet with specific security rules.

```
Internet Traffic
    ↓
API Management Gateway (Internal VNet)
    ↓
APIM Subnet (10.0.5.0/24)
    ↓
Container Apps (Internal Load Balancer)
    ↓
ACA Subnet (10.0.2.0/24)
    ↓
ACR Integration (private endpoint)
    ↓
ACR Subnet (10.0.1.0/24)

Administrative Access
    ↓
Azure Bastion (Public IP + Gateway)
    ↓
Bastion Subnet (10.0.4.0/24)
    ↓
Jumpbox Subnet (10.0.3.0/24)
    ↓
Jumpbox VM (Private IP)
```

### Private Endpoints & DNS

**Private Connectivity**: All PaaS services use private endpoints for network isolation.

```
Private Endpoints:
├── ACR Private Endpoint
│   ├── Subnet: ACR Subnet (10.0.1.0/24)
│   ├── Subresource: registry
│   └── Private DNS: privatelink.azurecr.io
│
├── APIM Private Endpoint
│   ├── Subnet: APIM Subnet (10.0.5.0/24)
│   ├── Subresource: Gateway
│   └── Private DNS: azure-api.net
│
└── Container Apps Private Connectivity
    ├── Type: Internal Load Balancer + Internal Ingress
    ├── Subnet: ACA Subnet (10.0.2.0/24)
    ├── External Access: Disabled (internal-only by default)
    └── Private DNS: <environment>.azurecontainerapps.io

Private DNS Zones:
- All DNS zones linked to VNet for internal resolution
- No public DNS records for private endpoints
- Automatic DNS record creation on private endpoint deployment
- Container App DNS A records point to internal load balancer

**Access Pattern**:
- All PaaS services (ACR, APIM, Container Apps, Foundry) are private-only by default
- This repository uses Bastion + jumpbox for private access; VPN/ExpressRoute are optional patterns but are not provisioned here
- For development/testing, external access can be enabled via terraform variables
```

### Identity & Access Control

#### Authentication Strategy

```
┌─────────────────────────────────────┐
│   Azure Container Apps              │
│  (User-Assigned Managed Identity)   │
└────────────────┬────────────────────┘
                 │ AcrPull role
                 ↓
    ┌────────────────────────┐
    │ Azure Container        │
    │ Registry               │
    │ (Image Storage)        │
    └────────────────────────┘
```

**Key Principles**:
- ✅ **No Service Principal Keys**: Managed identity eliminates credential management
- ✅ **RBAC Role**: AcrPull role scope to specific ACR
- ✅ **No Admin User**: ACR admin user disabled by default
- ✅ **Bastion Access Only**: Jumpbox access is via Bastion using Windows credentials

### Application Architecture

#### Container App Configuration

```
azlz-app (Container App)
│
├── Ingress: 443 (HTTPS only)
│   └── External: true (internet-facing)
│
├── Containers:
│   └── azlz-app:latest
│       ├── Image Source: ACR
│       ├── Resources: 0.5 CPU, 1GB RAM
│       ├── Port: 8080
│       │
│       ├── Health Checks:
│       │   ├── Liveness: /health (10s interval)
│       │   └── Readiness: /ready (5s interval)
│       │
│       └── Environment:
│           └── ASPNETCORE_URLS=http://+:8080
│
├── Scaling:
│   ├── Min Replicas: 1
│   ├── Max Replicas: 5
│   └── Trigger: HTTP requests/sec > 100
│
└── Logging:
    └── Log Analytics Workspace
```

#### .NET Application Design

**Minimal API Pattern**: Lightweight, fast startup, perfect for containers.

```csharp
// Health Check Endpoints
GET /health        → Basic health check
GET /ready         → Readiness check (more extensive)

// API Endpoints
GET /              → Application info
GET /api/info      → Detailed metrics
GET /api/environment → Runtime environment
POST /api/echo     → Echo service
```

**Advantages**:
- ✅ Small image size (100-200 MB)
- ✅ Fast cold start
- ✅ Low memory footprint
- ✅ Excellent for serverless/containers

## Best Practices Implementation

### 1. Network Security

#### NSG Rules Strategy
```
ACR Subnet NSG:
  ├── Allow: ACA Subnet → ACR (all ports)
  └── Deny: All other inbound

ACA Subnet NSG:
  ├── Allow: Internet → 443 (HTTPS)
  ├── Allow: Internet → 80 (HTTP)
  └── Implicit outbound to Azure services

Jumpbox NSG:
  ├── Allow: Bastion Subnet → 3389 (RDP)
  └── Deny: All other inbound (explicit)

Bastion NSG:
  ├── Allow: Internet → 443 (Gateway)
  ├── Allow: GatewayManager → 443
  ├── Allow: LoadBalancer → 443
  ├── Allow: VirtualNetwork ↔ 443
  └── Allow: Outbound for RDP to VirtualNetwork
```

#### Service Endpoints
- **ACR Subnet**: Microsoft.ContainerRegistry
- **ACR Subnet**: Microsoft.KeyVault
- **Benefits**: 
  - Restricts access to service from specific subnets
  - No internet exposure required
  - Reduces attack surface

### 2. Identity & Access Management (IAM)

#### Managed Identity Hierarchy
```
User-Assigned Identity
  └── Assigned to: Container App
      └── Role: AcrPull on ACR
          └── Permission: Pull images only (read-only)
```

#### Why This Approach?
- ✅ **No Secrets**: No connection strings, keys, or passwords in code
- ✅ **Automatic Rotation**: Azure manages token lifecycle
- ✅ **Least Privilege**: AcrPull role only (can't delete/push images)
- ✅ **Audit Trail**: All authentication requests logged

#### Jumpbox Authentication
```
Windows Jumpbox (Windows Server 2022):
  ├── Authentication: RDP username/password
  ├── Credentials: Admin account (set via variable)
  ├── Access: Via Bastion RDP tunnel
  └── Protocol: RDP (Remote Desktop Protocol)
```

### 3. Container Security

#### Dockerfile Security
```dockerfile
# Multi-stage build (reduces final image size)
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS builder
  ├── Purpose: Compilation stage
  ├── Size: Large (1+ GB)
  └── Not shipped in final image

FROM mcr.microsoft.com/dotnet/aspnet:10.0
  ├── Purpose: Runtime stage
  ├── Size: Small (100-200 MB)
  ├── Non-root user: 1000:1000
  └── Read-only filesystem: true (via ACA)
```

#### Runtime Security
```
Container Runtime
├── User: dotnetuser (UID 1000, non-root)
├── Capabilities: Dropped (securityContext in ACA)
├── Filesystem: Read-only (except /tmp)
├── Networking: No privileges
└── Syscalls: Restricted via seccomp (optional)
```

### 4. Health & Readiness Checks

#### Probe Configuration
```
Liveness Probe (Container health)
  ├── Endpoint: GET /health
  ├── Interval: 10 seconds
  ├── Timeout: 3 seconds
  ├── Start Delay: 5 seconds
  └── Action on Failure: Restart container

Readiness Probe (Service availability)
  ├── Endpoint: GET /ready
  ├── Interval: 5 seconds
  ├── Timeout: 3 seconds
  ├── Start Delay: 2 seconds
  └── Action on Failure: Remove from load balancer
```

#### Health Check Implementation
```csharp
// Simple health check
app.MapHealthChecks("/health");

// Detailed readiness
app.MapHealthChecks("/ready", new HealthCheckOptions
{
    Predicate = _ => true  // Include all checks
});
```

### 5. Logging & Monitoring

#### Log Analytics Integration
```
Container App
  └── Container Logs → Log Analytics Workspace
      ├── Retention: 30 days
      ├── Schema: ContainerAppConsoleLogs_CL
      └── Queryable: KQL (Kusto Query Language)

Sample KQL Queries:
┌─────────────────────────────────────────────┐
│ ContainerAppConsoleLogs_CL                  │
│ | where ContainerAppName_s == "azlz-app"   │
│ | summarize Count = count() by Level_s     │
│ | render barchart                          │
└─────────────────────────────────────────────┘
```

#### Metrics to Monitor
```
Container App Metrics:
├── CPU Usage %
├── Memory Usage MB
├── Request Count
├── Request Duration (avg, p95, p99)
├── Error Rate (5xx responses)
├── Active Replicas
└── Scaling Events

ACR Metrics:
├── Image count
├── Storage usage
└── Pull/Push operations

VM Metrics:
├── CPU %
├── Memory %
├── Network In/Out
└── Disk I/O
```

### 6. Data Protection

#### Encryption in Transit
- ✅ **TLS 1.2+**: All external connections (HTTPS)
- ✅ **Encrypted Subnets**: Optional (via NSG)
- ✅ **Service Endpoints**: Private connection to ACR/KeyVault

#### Encryption at Rest
- ✅ **OS Disks**: Platform-managed encryption
- ✅ **ACR Images**: At rest encryption (automatic)
- ✅ **Key Vault**: HSM-backed keys (optional, production)

#### Secret Management Strategy
```
❌ NOT RECOMMENDED:
  ├── Hardcoded secrets
  ├── Environment variables for sensitive data
  ├── Secrets in container images
  └── Plain text files

✅ RECOMMENDED:
  ├── Azure Key Vault
  ├── Managed Identity authentication
  ├── Secret rotation policies
  └── Audit logging of access
```

### 7. Cost Optimization

#### SKU Selection (Monthly, East US pricing)
```
ACR (Azure Container Registry):
  ├── Standard: $11/mo (100 GB storage, 100k pulls)
  │   └── Good for: Dev/test, lightweight workloads
  ├── Premium: $50/mo (500 GB storage, unlimited pulls)
  │   └── Good for: Private endpoints, geo-replication, production
  └── Premium + Private Endpoints: ~$50/mo additional networking

APIM (API Management):
  ├── Developer: $50/mo (no SLA, dev only)
  ├── Standard: $150/unit/mo (99.9% SLA)
  ├── StandardV2: $720/mo (99.99% SLA, auto-scaling)
  └── Note: Scaling adds $600+ per additional unit

ACA (Container Apps, Consumption Plan):
  ├── Pricing: Per vCPU-hour + memory-hour
  ├── ~$0.0278/vCPU-hour + $0.0111/GB-hour
  ├── 0.5 vCPU, 1GB RAM = ~$20-23/month per replica
  └── Auto-scales to zero when no requests (serverless)

Windows Jumpbox VM:
  ├── Windows D4s_v5: $180/mo (4 vCPU, 16GB RAM, dedicated)
  ├── Spot VM: 60-70% discount if preemption acceptable
  └── Good for: Development, bastion, CI/CD runners

Azure Bastion:
  ├── Basic: $5.50/hour = ~$365/month (hourly billing)
  ├── Standard: $15/hour = ~$1,095/month (bundled bandwidth)
  └── Note: Budget-friendly alternative = Private Link to VMs

Log Analytics:
  ├── Pay-as-you-go: $2.99/GB ingested, $0.90/GB retention
  ├── Commitment tier: 100 GB/day = ~$190/mo
  ├── 30-day retention: Good for dev/test environments
  └── Free tier: 5GB/day (limited to 7 days)
```

#### Current Deployment Costs

**Dev Environment** (~$1,346/mo in East US):
- ACR Premium: $50/mo
- APIM StandardV2: $720/mo
- ACA (1 replica): $23/mo
- Windows VM (D4s_v5): $180/mo
- Azure Bastion Basic: $365/mo
- Log Analytics: $8/mo

**Cost Reduction Strategies**
```
1. ACR Standard instead of Premium
   └── Saves $39/mo if private endpoints not required

2. APIM Developer tier for non-production
   └── Saves $670/mo but has lower SLA/limits

3. Disable Bastion when not in use
   └── Saves $365/mo (hourly billing only charges when running)

4. Scale ACA to Zero
   └── Container Apps automatically scales to 0 replicas
   └── Saves $23/mo per replica when idle

5. Spot VMs for development
   └── Standard_B2s Spot: ~$11/mo (70% savings)
   └── Risk: VMs preempted with 30s notice

6. Reserved Instances (longer commitments)
   └── 1-year reservation: 20-30% discount on VMs
   └── 3-year reservation: 40-50% discount on VMs

5. Bastion Basic tier
   └── Sufficient for most use cases
```

### 8. Disaster Recovery

#### RTO/RPO Targets
```
Service          RTO     RPO     Strategy
─────────────────────────────────────────────
Container App    5 min   0       Replicas + auto-heal
ACR              30 min  1 day   Geo-replication (prod)
Log Analytics    1 hour  1 day   Standard retention
Database         N/A     N/A     Backup policy (future)
```

#### Backup Strategy
```
Container Images:
  ├── ACR Retention Policy: 30 days
  ├── Manual Export: Tag as ":stable", ":v1.0"
  └── Production: Geo-replication to 2nd region

Application State:
  ├── Container Apps: Stateless design
  ├── Data: External database (future)
  └── Configuration: In Key Vault, version controlled

Infrastructure:
  ├── Terraform: Version in Git
  ├── Variables: Separate per environment
  └── Automation: Redeploy in minutes
```

### 9. Compliance & Governance

#### Security Baselines
```
✅ Implemented:
  ├── Network isolation (NSGs, service endpoints)
  ├── Identity verification (managed identity)
  ├── Encryption in transit (HTTPS/TLS)
  ├── Non-root containers
  ├── Health checks
  ├── Audit logging (Activity Log)
  ├── Infrastructure as Code (Terraform)
  └── Regular monitoring

🔲 Future Additions:
  ├── Web Application Firewall (Application Gateway)
  ├── DDoS Protection Standard
  ├── Advanced Threat Protection
  ├── Compliance scanning (Azure Defender)
  └── Data encryption at rest (premium)
```

#### Audit & Compliance
```
What's Logged:
  ├── Azure Activity Log: All resource changes
  ├── Container Logs: Application output
  ├── Diagnostic Logs: Resource health events
  └── Managed Identity: Token requests

Retention:
  ├── Activity Log: 90 days (free)
  ├── Extended: Send to Log Analytics (30+ days)
  └── Compliance: Keep for regulatory period

Query Example (KQL):
┌──────────────────────────────────────┐
│ AzureActivity                         │
│ | where OperationName contains "ACR" │
│ | summarize by Caller                │
└──────────────────────────────────────┘
```

## Scalability Considerations

### Horizontal Scaling
```
Container App Replicas:
┌──────────────┐
│ Replica 1    │
│ azlz-app     │
│ 0.5 CPU      │
└──────────────┘
        ↓ (load increases)
┌──────────────┐   ┌──────────────┐
│ Replica 1    │   │ Replica 2    │
│ azlz-app     │   │ azlz-app     │
│ 0.5 CPU      │   │ 0.5 CPU      │
└──────────────┘   └──────────────┘
        ↓ (load increases further)
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│ Replica 1    │   │ Replica 2    │   │ Replica 3    │
└──────────────┘   └──────────────┘   └──────────────┘
        ↓ (up to 5 replicas max)
```

### Scaling Policies
```
Current Policy:
  ├── Metric: HTTP requests/second > 100
  ├── Min Replicas: 1
  └── Max Replicas: 5

Recommended Enhancements:
  ├── CPU-based scaling: > 70% usage
  ├── Memory-based scaling: > 80% usage
  └── Custom metrics: Business logic
```

## Production Readiness Checklist

```
Network & Security
  ☑ NSGs configured with least privilege
  ☑ Service endpoints enabled
  ☑ Bastion deployed for jumpbox access
  ☑ No public IPs on application VMs
  ☑ Encryption in transit enabled

Identity & Access
  ☑ Managed identity configured
  ☑ IAM roles assigned (AcrPull)
  ☑ Windows jumpbox credentials managed via secure secrets
  ☑ No hardcoded secrets
  ☑ Key Vault for secrets (future)

Application
  ☑ Health checks implemented
  ☑ Startup/liveness probes configured
  ☑ Error handling implemented
  ☑ Logging enabled
  ☑ Graceful shutdown handled

Container
  ☑ Non-root user
  ☑ Minimal image size
  ☑ Security scanning enabled (future)
  ☑ Read-only filesystem (future)
  ☑ Resource limits set

Monitoring
  ☑ Log Analytics workspace deployed
  ☑ Metrics collection enabled
  ☑ Alerts configured
  ☑ Audit logging enabled
  ☑ Dashboard created (future)

Operations
  ☑ Backup strategy defined
  ☑ DR plan documented
  ☑ Runbooks created
  ☑ Documentation complete
  ☑ Team trained

Infrastructure as Code
  ☑ Terraform: Version-controlled IaC
  ☑ Modular organization: provider, main, variables, outputs
  ☑ State management: Explicit tracking
  ☑ Remote state ready: For team collaboration
```

