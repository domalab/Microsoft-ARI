# Use the official PowerShell 7.4 image on Ubuntu 22.04
FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04

# Avoid warnings by switching to noninteractive
ARG DEBIAN_FRONTEND=noninteractive

# Create a non-root user first (to minimize layer size)
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Configure apt and install packages in a single layer
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
        apt-utils \
        dialog \
        git \
        curl \
        ca-certificates \
        gnupg \
        lsb-release \
        sudo \
    # Install Azure CLI (minimal installation)
    && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    # Create user
    && groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    # Clean up apt cache and remove unnecessary packages
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

# Set PowerShell as the default shell
SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Install required PowerShell modules (execution policy not needed on Linux)
RUN Write-Host "Installing PowerShell modules..." ; \
    Install-Module -Name ImportExcel -Force -Scope AllUsers -AcceptLicense -Repository PSGallery ; \
    Install-Module -Name Az.Accounts -Force -Scope AllUsers -AcceptLicense -Repository PSGallery ; \
    Install-Module -Name Az.ResourceGraph -Force -Scope AllUsers -AcceptLicense -Repository PSGallery ; \
    Install-Module -Name Az.Storage -Force -Scope AllUsers -AcceptLicense -Repository PSGallery ; \
    Install-Module -Name Az.Compute -Force -Scope AllUsers -AcceptLicense -Repository PSGallery ; \
    Install-Module -Name Az.CostManagement -Force -Scope AllUsers -AcceptLicense -Repository PSGallery ; \
    Install-Module -Name PSScriptAnalyzer -Force -Scope AllUsers -AcceptLicense -Repository PSGallery ; \
    Install-Module -Name Pester -Force -Scope AllUsers -AcceptLicense -Repository PSGallery ; \
    Write-Host "PowerShell modules installed successfully"

# Switch to vscode user and set up profile using bash shell
USER $USERNAME
SHELL ["/bin/bash", "-c"]
RUN mkdir -p /home/vscode/.config/powershell \
    && echo '# PowerShell Profile for ARI Development' > /home/vscode/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo 'Write-Host "Azure Resource Inventory Development Environment" -ForegroundColor Green' >> /home/vscode/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo 'Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan' >> /home/vscode/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo 'Set-Alias -Name ll -Value Get-ChildItem' >> /home/vscode/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo 'Set-Alias -Name la -Value "Get-ChildItem -Force"' >> /home/vscode/.config/powershell/Microsoft.PowerShell_profile.ps1

# Set the default working directory and environment variables
WORKDIR /workspace
ENV POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Ubuntu-22.04