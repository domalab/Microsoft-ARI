# Azure Resource Inventory - Production Runtime Container
# Optimized for execution in enterprise environments
FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04

# Build-time arguments
ARG ARI_VERSION=latest
ARG BUILD_DATE
ARG VCS_REF

# Labels for container metadata
LABEL org.opencontainers.image.title="Azure Resource Inventory" \
      org.opencontainers.image.description="Containerized Azure Resource Inventory tool for enterprise environments" \
      org.opencontainers.image.version="${ARI_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.vendor="Microsoft" \
      org.opencontainers.image.source="https://github.com/microsoft/ARI" \
      org.opencontainers.image.documentation="https://github.com/microsoft/ARI/blob/main/containers/README.md"

# Avoid warnings by switching to noninteractive
ARG DEBIAN_FRONTEND=noninteractive

# Install system dependencies and Azure CLI in a single layer
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
        curl \
        ca-certificates \
        gnupg \
        lsb-release \
        bash \
    # Install Azure CLI (minimal installation)
    && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    # Create application user (non-root for security)
    && useradd --create-home --shell /bin/bash ariuser \
    # Clean up aggressively
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/* \
    && rm -rf /usr/share/doc/* \
    && rm -rf /usr/share/man/*

# Set PowerShell as the default shell
SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Install only essential PowerShell modules for ARI execution
RUN Write-Host "Installing essential PowerShell modules for ARI..." ; \
    Install-Module -Name ImportExcel -Force -Scope AllUsers -AcceptLicense -Repository PSGallery ; \
    Install-Module -Name Az.Accounts -Force -Scope AllUsers -AcceptLicense -Repository PSGallery ; \
    Install-Module -Name Az.ResourceGraph -Force -Scope AllUsers -AcceptLicense -Repository PSGallery ; \
    Install-Module -Name Az.Storage -Force -Scope AllUsers -AcceptLicense -Repository PSGallery ; \
    Install-Module -Name Az.Compute -Force -Scope AllUsers -AcceptLicense -Repository PSGallery ; \
    Install-Module -Name Az.CostManagement -Force -Scope AllUsers -AcceptLicense -Repository PSGallery ; \
    # Clean up PowerShell module cache and temporary files
    Get-ChildItem -Path "$env:TEMP" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue ; \
    # Remove module installation logs and cache
    Get-ChildItem -Path "/opt/microsoft/powershell/7" -Name "*.log" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue ; \
    Write-Host "Essential PowerShell modules installed successfully"

# Copy ARI module files
COPY . /opt/ari/
WORKDIR /opt/ari

# Create output directory with PowerShell commands
SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
RUN New-Item -ItemType Directory -Path '/ari-output' -Force

# Switch to non-root user
USER ariuser

# Create minimal PowerShell profile for ARI execution
RUN mkdir -p ~/.config/powershell \
    && echo '# ARI Runtime Profile' > ~/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo 'Write-Host "Azure Resource Inventory Runtime Container" -ForegroundColor Green' >> ~/.config/powershell/Microsoft.PowerShell_profile.ps1

# Set environment variables
ENV POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Ubuntu-22.04-ARI \
    ARI_CONTAINER_MODE=true \
    ARI_OUTPUT_PATH=/ari-output

# Default working directory for output
WORKDIR /ari-output

# Health check to ensure ARI module can be loaded
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pwsh -c "Import-Module /opt/ari/AzureResourceInventory.psm1; if (Get-Command Invoke-ARI -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }"

# Default command: show help and available parameters
CMD ["pwsh", "-c", "Import-Module /opt/ari/AzureResourceInventory.psm1; Write-Host 'Azure Resource Inventory Container' -ForegroundColor Green; Write-Host 'Usage: docker run --rm -v $(pwd)/output:/ari-output ari:latest pwsh -c \"Import-Module /opt/ari/AzureResourceInventory.psm1; Invoke-ARI [parameters]\"' -ForegroundColor Cyan; Write-Host 'For help: docker run --rm ari:latest pwsh -c \"Import-Module /opt/ari/AzureResourceInventory.psm1; Get-Help Invoke-ARI -Full\"' -ForegroundColor Yellow"]