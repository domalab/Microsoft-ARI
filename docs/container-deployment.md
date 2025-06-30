# Enterprise Container Deployment Guide

This guide provides comprehensive instructions for deploying Azure Resource Inventory (ARI) containers in enterprise environments, specifically designed to bypass PowerShell restrictions and security policies.

## Table of Contents

- [Overview](#overview)
- [Enterprise Challenges](#enterprise-challenges)
- [Container Solution Benefits](#container-solution-benefits)
- [Prerequisites](#prerequisites)
- [Installation Methods](#installation-methods)
- [Authentication Strategies](#authentication-strategies)
- [Network Requirements](#network-requirements)
- [Security Considerations](#security-considerations)
- [Deployment Scenarios](#deployment-scenarios)
- [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
- [Maintenance and Updates](#maintenance-and-updates)

## Overview

The ARI container solution enables organizations to run Azure Resource Inventory in environments where PowerShell execution is restricted by security policies. This containerized approach provides a consistent, isolated environment that bypasses common enterprise PowerShell limitations.

## Enterprise Challenges

### Common PowerShell Restrictions

**Execution Policy Limitations:**
- GPO/Intune enforcement of Restricted or AllSigned policies
- User inability to override execution policies
- Script blocking at the organizational level

**ConstrainedLanguage Mode:**
- Enforced through AppLocker or Windows Defender Application Control
- PSLockdownPolicy restrictions preventing Azure module operations
- Automatic activation based on application control policies

**Module Installation Issues:**
- No administrative privileges for module installation
- PowerShell Gallery blocked by corporate firewalls/proxies
- Outdated or incompatible module versions in corporate repositories
- Certificate trust issues with external repositories

**Environment Restrictions:**
- Locked-down PowerShell versions (stuck on 5.1)
- Network proxy authentication requirements
- Corporate certificate requirements

### Business Impact

- **Delayed Reporting:** Manual inventory processes taking weeks instead of hours
- **Inconsistent Data:** Different teams using different tools and methods
- **Security Gaps:** Inability to run compliance and security assessments
- **Resource Waste:** IT staff spending excessive time on manual tasks

## Container Solution Benefits

### Technical Benefits

✅ **Complete Isolation:** Bypasses all host PowerShell restrictions  
✅ **Consistent Environment:** Same PowerShell and module versions everywhere  
✅ **No Installation Required:** Only Docker Desktop needed  
✅ **Network Independence:** Container handles all Azure API calls  
✅ **Cross-Platform:** Works on Windows, Linux, and Mac  

### Business Benefits

✅ **Rapid Deployment:** Get running in minutes, not days  
✅ **Standardization:** Same tool across all environments  
✅ **Compliance:** Enables regular security and compliance reporting  
✅ **Cost Reduction:** Eliminates manual inventory processes  
✅ **Risk Mitigation:** Reduces human error in asset tracking  

## Prerequisites

### Software Requirements

**Docker Desktop:**
- Windows: Docker Desktop for Windows 4.0+
- macOS: Docker Desktop for Mac 4.0+
- Linux: Docker Engine 20.0+ and Docker Compose

**System Requirements:**
- 4GB RAM minimum, 8GB recommended
- 10GB available disk space
- Network access to Azure APIs

### Azure Requirements

**Authentication:**
- Azure account with appropriate permissions
- Service Principal (recommended for automation)
- Device code authentication capability (for interactive use)

**Permissions:**
- Reader role on target subscriptions
- Optional: Security Reader for Security Center data
- Optional: Cost Management Reader for cost data

## Installation Methods

### Method 1: Pre-built Container (Recommended)

```bash
# Pull from public registry (when available)
docker pull ghcr.io/microsoft/ari:latest

# Or build locally
git clone https://github.com/microsoft/ARI.git
cd ARI
docker build -t ari:latest containers/runtime/
```

### Method 2: Enterprise Registry

For organizations with private container registries:

```bash
# Build and tag for private registry
docker build -t your-registry.com/ari:latest containers/runtime/
docker push your-registry.com/ari:latest

# Deploy to workstations
docker pull your-registry.com/ari:latest
```

### Method 3: Offline Installation

For air-gapped environments:

```bash
# On internet-connected machine
docker build -t ari:latest containers/runtime/
docker save ari:latest > ari-container.tar

# Transfer file to air-gapped environment
# On air-gapped machine
docker load < ari-container.tar
```

## Authentication Strategies

### Service Principal (Recommended for Automation)

**Create Service Principal:**
```bash
# Create service principal with Reader role
az ad sp create-for-rbac \
  --name "ARI-ServicePrincipal" \
  --role "Reader" \
  --scope "/subscriptions/{subscription-id}"

# Note the output: appId, password, tenant
```

**Environment Configuration:**
```bash
export AZURE_CLIENT_ID="your-app-id"
export AZURE_CLIENT_SECRET="your-password"
export AZURE_TENANT_ID="your-tenant-id"
```

### Device Code Authentication

Best for interactive use and testing:

```bash
# Container will prompt for device code
# User opens browser and enters code
./containers/scripts/run-ari.sh --device-login --tenant-id "your-tenant-id"
```

### Azure CLI Integration

Mount existing Azure CLI credentials:

```bash
# If Azure CLI is configured on host
./containers/scripts/run-ari.sh --mount-azure-config --tenant-id "your-tenant-id"
```

### Managed Identity

For Azure-hosted containers (Azure Container Instances, etc.):

```bash
# Container automatically uses managed identity
# No additional configuration required
```

## Network Requirements

### Firewall Rules

**Required Outbound Access:**
- `*.core.windows.net` (Azure Storage)
- `management.azure.com` (Azure Resource Manager)
- `graph.microsoft.com` (Microsoft Graph)
- `login.microsoftonline.com` (Azure AD)
- `*.blob.core.windows.net` (Azure Storage)

**Optional (for full functionality):**
- `*.vault.azure.net` (Azure Key Vault)
- `*.database.windows.net` (Azure SQL)
- `*.servicebus.windows.net` (Service Bus)

### Proxy Configuration

**HTTP Proxy Support:**
```bash
# Set proxy environment variables
export HTTP_PROXY="http://proxy.company.com:8080"
export HTTPS_PROXY="http://proxy.company.com:8080"
export NO_PROXY="localhost,127.0.0.1,.company.com"

# Run with proxy settings
docker run --rm -it \
  -e HTTP_PROXY \
  -e HTTPS_PROXY \
  -e NO_PROXY \
  -v $(pwd)/output:/ari-output \
  ari:latest
```

**Authenticated Proxy:**
```bash
export HTTP_PROXY="http://username:password@proxy.company.com:8080"
export HTTPS_PROXY="http://username:password@proxy.company.com:8080"
```

## Security Considerations

### Container Security

**Image Scanning:**
```bash
# Scan for vulnerabilities
docker scan ari:latest

# Use specific base image versions
FROM mcr.microsoft.com/powershell:7.4.6-ubuntu-22.04
```

**Non-root Execution:**
- Container runs as non-root user `ariuser`
- No privileged access required
- Read-only filesystem except for output directory

**Network Isolation:**
```yaml
# Docker Compose with network isolation
networks:
  ari_isolated:
    driver: bridge
    internal: true  # No external access except through gateway
```

### Data Protection

**Output Security:**
- Reports contain sensitive infrastructure information
- Ensure output directories have appropriate permissions
- Consider encryption for stored reports

**Credential Management:**
- Never store credentials in container images
- Use environment variables or mounted secrets
- Rotate service principal credentials regularly

**Audit Logging:**
```bash
# Enable Docker logging
docker run --rm -it \
  --log-driver=json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  ari:latest
```

### Compliance Considerations

**Data Residency:**
- Container processes data in memory only
- No persistent data storage in container
- Output files written to host-mounted volumes

**Access Control:**
- Implement RBAC for container registry access
- Control who can run containers
- Audit container execution

## Deployment Scenarios

### Scenario 1: Developer Workstations

**Use Case:** Individual developers need occasional inventory reports

**Solution:**
```bash
# Simple wrapper script deployment
git clone https://github.com/microsoft/ARI.git
cd ARI
chmod +x containers/scripts/run-ari.sh
./containers/scripts/run-ari.sh --tenant-id "your-tenant-id"
```

**Group Policy Deployment:**
- Deploy Docker Desktop via GPO
- Distribute wrapper scripts via network share
- Configure environment variables centrally

### Scenario 2: Automated Reporting

**Use Case:** Weekly/monthly automated inventory reports

**Solution:**
```bash
# Scheduled execution with service principal
./containers/scripts/run-ari.sh \
  --service-principal \
  --tenant-id "your-tenant-id" \
  --report-name "Weekly-$(date +%Y%m%d)" \
  --output ./reports/$(date +%Y-%m)
```

**Enterprise Scheduler Integration:**
- Windows Task Scheduler
- Linux cron jobs
- Enterprise job schedulers (Control-M, etc.)

### Scenario 3: CI/CD Integration

**Use Case:** Include inventory in deployment pipelines

**Solution:** See [CI/CD Examples](../containers/examples/ci-cd-examples.md)

### Scenario 4: Multi-tenant Environments

**Use Case:** MSPs managing multiple customer tenants

**Solution:**
```bash
# Multi-tenant configuration
cp containers/.env.example containers/.env
# Configure tenants.json with customer details
docker-compose --profile multitenant up ari-multitenant
```

### Scenario 5: Air-gapped Environments

**Use Case:** Secure environments without internet access

**Prerequisites:**
- Pre-built container image
- Offline Azure Stack or Azure Government access

**Solution:**
```bash
# Load pre-built container
docker load < ari-container.tar

# Configure for offline Azure endpoints
export AZURE_ENVIRONMENT="AzureUSGovernment"
./containers/scripts/run-ari.sh --tenant-id "your-tenant-id"
```

## Monitoring and Troubleshooting

### Container Health Monitoring

**Health Checks:**
```bash
# Check container health
docker inspect --format='{{.State.Health.Status}}' ari-container

# View health check logs
docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' ari-container
```

**Resource Monitoring:**
```bash
# Monitor resource usage
docker stats ari-container

# Set resource limits
docker run --rm -it \
  --memory=2g \
  --cpus=1.0 \
  ari:latest
```

### Common Issues and Solutions

**Issue: Container fails to start**
```bash
# Check Docker service
systemctl status docker  # Linux
# or check Docker Desktop on Windows/Mac

# Check image exists
docker images | grep ari

# Check for resource constraints
docker system df
```

**Issue: Authentication failures**
```bash
# Verify service principal
az login --service-principal \
  --username $AZURE_CLIENT_ID \
  --password $AZURE_CLIENT_SECRET \
  --tenant $AZURE_TENANT_ID

# Test Azure connectivity
docker run --rm -it \
  -e AZURE_CLIENT_ID \
  -e AZURE_CLIENT_SECRET \
  -e AZURE_TENANT_ID \
  ari:latest \
  pwsh -c "Connect-AzAccount -ServicePrincipal -Credential (New-Object PSCredential('$env:AZURE_CLIENT_ID', (ConvertTo-SecureString '$env:AZURE_CLIENT_SECRET' -AsPlainText -Force))) -Tenant '$env:AZURE_TENANT_ID'"
```

**Issue: Network connectivity problems**
```bash
# Test Azure endpoints
docker run --rm -it ari:latest \
  pwsh -c "Test-NetConnection management.azure.com -Port 443"

# Check proxy settings
echo $HTTP_PROXY
echo $HTTPS_PROXY
```

**Issue: Permission denied errors**
```bash
# Check output directory permissions
ls -la ./ari-output/

# Fix permissions
chmod 755 ./ari-output/
```

### Logging and Debugging

**Enable Debug Mode:**
```bash
# Wrapper script debug
./containers/scripts/run-ari.sh --debug --tenant-id "your-tenant-id"

# PowerShell debug in container
docker run --rm -it \
  -v $(pwd)/output:/ari-output \
  ari:latest \
  pwsh -c "Set-PSDebug -Trace 1; Import-Module /opt/ari/AzureResourceInventory.psm1; Invoke-ARI -Debug"
```

**Container Logs:**
```bash
# View container logs
docker logs ari-container

# Follow logs in real-time
docker logs -f ari-container

# Save logs to file
docker logs ari-container > ari-execution.log 2>&1
```

## Maintenance and Updates

### Container Updates

**Check for Updates:**
```bash
# Pull latest version
docker pull ari:latest

# Compare versions
docker images | grep ari
```

**Update Process:**
```bash
# Stop running containers
docker stop $(docker ps -q --filter ancestor=ari:latest)

# Pull new version
docker pull ari:latest

# Clean up old images
docker image prune -f
```

### Backup and Recovery

**Backup Essential Components:**
- Container configuration files (docker-compose.yml, .env)
- Wrapper scripts and customizations
- Service principal credentials (encrypted)
- Generated reports (if needed for compliance)

**Disaster Recovery:**
```bash
# Export container image
docker save ari:latest > ari-backup.tar

# Export configuration
tar -czf ari-config-backup.tar.gz \
  containers/docker-compose.yml \
  containers/.env \
  containers/scripts/
```

### Security Updates

**Regular Maintenance Tasks:**
- Update base container images monthly
- Rotate service principal credentials quarterly
- Review and update firewall rules semi-annually
- Scan containers for vulnerabilities before deployment

**Security Monitoring:**
```bash
# Regular vulnerability scans
docker scan ari:latest

# Check for security updates
docker pull mcr.microsoft.com/powershell:latest
```

## Support and Escalation

### Internal Support

**First Level:**
- Check container health and logs
- Verify network connectivity
- Validate Azure permissions

**Second Level:**
- Review Azure API responses
- Analyze PowerShell execution errors
- Check resource constraints

### External Support

**Microsoft Support:**
- Azure subscription issues
- Service principal problems
- Azure API limitations

**Community Support:**
- GitHub repository issues
- PowerShell community forums
- Docker community resources

### Documentation and Training

**Administrator Training:**
- Docker fundamentals
- Azure authentication concepts
- Container security best practices
- Troubleshooting methodologies

**User Training:**
- Basic container execution
- Authentication procedures
- Report interpretation
- Common issue resolution