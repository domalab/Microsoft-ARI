# ARI Container Quick Start Guide

This guide helps you get started with running Azure Resource Inventory in a Docker container to bypass PowerShell restrictions.

## Prerequisites

- Docker Desktop installed and running
- Azure account with read access to resources
- Basic familiarity with command line

## Method 1: Simple Wrapper Script (Recommended)

### Linux/Mac
```bash
# Make script executable
chmod +x containers/scripts/run-ari.sh

# Basic usage - will prompt for device login
./containers/scripts/run-ari.sh --tenant-id "12345678-1234-1234-1234-123456789012"

# With specific subscription
./containers/scripts/run-ari.sh \
  --tenant-id "12345678-1234-1234-1234-123456789012" \
  --subscription-id "abcd-efgh-ijkl-mnop-qrstuvwxyz01"

# Include tags and security center data
./containers/scripts/run-ari.sh \
  --tenant-id "12345678-1234-1234-1234-123456789012" \
  --include-tags \
  --security-center
```

### Windows PowerShell
```powershell
# Basic usage
.\containers\scripts\run-ari.ps1 -TenantId "12345678-1234-1234-1234-123456789012"

# With specific subscription and tags
.\containers\scripts\run-ari.ps1 `
  -TenantId "12345678-1234-1234-1234-123456789012" `
  -SubscriptionId "abcd-efgh-ijkl-mnop-qrstuvwxyz01" `
  -IncludeTags

# Custom output directory
.\containers\scripts\run-ari.ps1 `
  -TenantId "12345678-1234-1234-1234-123456789012" `
  -OutputPath "C:\ARI-Reports" `
  -ReportName "CompanyInventory"
```

### Windows Command Prompt (Batch)
```cmd
# Basic usage
containers\scripts\run-ari.bat "12345678-1234-1234-1234-123456789012"

# With subscription ID
containers\scripts\run-ari.bat "12345678-1234-1234-1234-123456789012" "abcd-efgh-ijkl-mnop-qrstuvwxyz01"

# With additional parameters
containers\scripts\run-ari.bat "12345678-1234-1234-1234-123456789012" "" -IncludeTags -SecurityCenter
```

## Method 2: Direct Docker Command

### Build the container first
```bash
# From the project root directory
docker build -t ari:latest containers/runtime/
```

### Run with device login (interactive)
```bash
# Create output directory
mkdir -p ./ari-output

# Run ARI container
docker run --rm -it \
  -v $(pwd)/ari-output:/ari-output \
  ari:latest \
  pwsh -c "Import-Module /opt/ari/AzureResourceInventory.psm1; Invoke-ARI -TenantID '12345678-1234-1234-1234-123456789012'"
```

### Windows version
```cmd
# Create output directory
mkdir ari-output

# Run ARI container
docker run --rm -it ^
  -v "%cd%\ari-output:/ari-output" ^
  ari:latest ^
  pwsh -c "Import-Module /opt/ari/AzureResourceInventory.psm1; Invoke-ARI -TenantID '12345678-1234-1234-1234-123456789012'"
```

## Method 3: Docker Compose

### Quick setup
```bash
# Copy environment template
cp containers/.env.example containers/.env

# Edit the environment file
nano containers/.env
# Set at minimum: ARI_TENANT_ID

# Run with Docker Compose
cd containers/
docker-compose --profile interactive up ari
```

## Expected Output

When successful, you'll see:
1. Container starts and loads PowerShell modules
2. Azure authentication prompt (browser will open for device login)
3. Progress messages as ARI collects data
4. Final Excel report saved to output directory

## Troubleshooting

### Container fails to start
```bash
# Check Docker is running
docker info

# Check if image exists
docker images | grep ari

# Build image if missing
docker build -t ari:latest containers/runtime/
```

### Authentication fails
```bash
# For device login, ensure browser access
# For service principal, check environment variables:
echo $AZURE_CLIENT_ID
echo $AZURE_TENANT_ID
# Don't echo the secret!
```

### Permission errors
```bash
# Ensure output directory is writable
ls -la ./ari-output/

# On Windows, ensure Docker has access to the drive
```

### No output files
```bash
# Check container logs
docker logs [container-name]

# Verify Azure permissions
# User/service principal needs Reader role on subscriptions
```

## Next Steps

- [Enterprise Deployment Guide](../docs/container-deployment.md)
- [CI/CD Integration Examples](./ci-cd-examples.md)
- [Multi-tenant Configuration](./multi-tenant-example.json)
- [Troubleshooting Guide](./troubleshooting.md)