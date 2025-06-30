<#
.SYNOPSIS
    Azure Resource Inventory - Container Wrapper Script for Windows
    
.DESCRIPTION
    Simplifies running ARI in a Docker container for enterprise Windows environments.
    This script bypasses local PowerShell restrictions by running ARI in a container.
    
.PARAMETER TenantId
    Azure tenant ID
    
.PARAMETER SubscriptionId
    Azure subscription ID
    
.PARAMETER ResourceGroup
    Limit to specific resource group
    
.PARAMETER OutputPath
    Output directory (default: .\ari-output)
    
.PARAMETER Image
    ARI container image to use (default: ari:latest)
    
.PARAMETER IncludeTags
    Include resource tags in report
    
.PARAMETER SecurityCenter
    Include Security Center data
    
.PARAMETER SkipAdvisory
    Skip Azure Advisory data
    
.PARAMETER ReportName
    Custom report name
    
.PARAMETER Lite
    Generate lightweight report
    
.PARAMETER DeviceLogin
    Use device code authentication (default)
    
.PARAMETER ServicePrincipal
    Use service principal authentication (requires environment variables)
    
.PARAMETER MountAzureConfig
    Mount local Azure configuration directory
    
.PARAMETER NoPull
    Don't pull latest image before running
    
.PARAMETER Debug
    Enable debug output
    
.PARAMETER Help
    Show detailed help information
    
.EXAMPLE
    .\run-ari.ps1 -TenantId "12345678-1234-1234-1234-123456789012"
    
.EXAMPLE
    .\run-ari.ps1 -TenantId "12345678-1234-1234-1234-123456789012" -SubscriptionId "abcd-efgh" -IncludeTags
    
.EXAMPLE
    .\run-ari.ps1 -OutputPath "C:\Reports" -ReportName "MyCompanyInventory" -TenantId "12345678-1234-1234-1234-123456789012"
    
.NOTES
    Version: 1.0.0
    Requires Docker Desktop for Windows
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\ari-output",
    
    [Parameter(Mandatory = $false)]
    [string]$Image = "ari:latest",
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeTags,
    
    [Parameter(Mandatory = $false)]
    [switch]$SecurityCenter,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipAdvisory,
    
    [Parameter(Mandatory = $false)]
    [string]$ReportName,
    
    [Parameter(Mandatory = $false)]
    [switch]$Lite,
    
    [Parameter(Mandatory = $false)]
    [switch]$DeviceLogin,
    
    [Parameter(Mandatory = $false)]
    [switch]$ServicePrincipal,
    
    [Parameter(Mandatory = $false)]
    [switch]$MountAzureConfig,
    
    [Parameter(Mandatory = $false)]
    [switch]$NoPull,
    
    [Parameter(Mandatory = $false)]
    [switch]$Debug,
    
    [Parameter(Mandatory = $false)]
    [switch]$Help,
    
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$AdditionalParams
)

# Script version
$ScriptVersion = "1.0.0"

# Function to write colored output
function Write-ColoredOutput {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )
    
    switch ($Type) {
        'Info'    { Write-Host "[INFO] $Message" -ForegroundColor Blue }
        'Success' { Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
        'Warning' { Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
        'Error'   { Write-Host "[ERROR] $Message" -ForegroundColor Red }
    }
}

# Function to show detailed help
function Show-DetailedHelp {
    Write-Host "Azure Resource Inventory - Container Runner v$ScriptVersion" -ForegroundColor Green
    Write-Host ""
    Write-Host "This script runs ARI in a Docker container to bypass PowerShell restrictions." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\run-ari.ps1 [PARAMETERS]"
    Write-Host ""
    Write-Host "CONTAINER OPTIONS:" -ForegroundColor Yellow
    Write-Host "  -OutputPath DIR           Output directory (default: .\ari-output)"
    Write-Host "  -Image IMAGE              Use specific ARI container image (default: ari:latest)"
    Write-Host "  -NoPull                   Don't pull latest image before running"
    Write-Host "  -Debug                    Enable debug output"
    Write-Host ""
    Write-Host "AZURE AUTHENTICATION:" -ForegroundColor Yellow
    Write-Host "  -DeviceLogin              Use device code authentication (default)"
    Write-Host "  -ServicePrincipal         Use service principal (requires env vars)"
    Write-Host "  -MountAzureConfig         Mount local Azure configuration"
    Write-Host ""
    Write-Host "ARI PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -TenantId ID              Azure tenant ID"
    Write-Host "  -SubscriptionId ID        Azure subscription ID"
    Write-Host "  -ResourceGroup RG         Limit to specific resource group"
    Write-Host "  -IncludeTags              Include resource tags in report"
    Write-Host "  -SecurityCenter           Include Security Center data"
    Write-Host "  -SkipAdvisory             Skip Azure Advisory data"
    Write-Host "  -ReportName NAME          Custom report name"
    Write-Host "  -Lite                     Generate lightweight report"
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  # Basic usage with device login"
    Write-Host '  .\run-ari.ps1 -TenantId "12345678-1234-1234-1234-123456789012"' -ForegroundColor Gray
    Write-Host ""
    Write-Host "  # Specific subscription with tags"
    Write-Host '  .\run-ari.ps1 -TenantId "12345678-1234-1234-1234-123456789012" -SubscriptionId "abcd-efgh" -IncludeTags' -ForegroundColor Gray
    Write-Host ""
    Write-Host "  # Custom output directory and report name"
    Write-Host '  .\run-ari.ps1 -OutputPath "C:\Reports" -ReportName "MyCompanyInventory" -TenantId "12345678-1234-1234-1234-123456789012"' -ForegroundColor Gray
    Write-Host ""
    Write-Host "For complete ARI parameter documentation:" -ForegroundColor Cyan
    Write-Host '  docker run --rm ari:latest pwsh -c "Import-Module /opt/ari/AzureResourceInventory.psm1; Get-Help Invoke-ARI -Full"' -ForegroundColor Gray
}

# Function to check if Docker is available
function Test-DockerAvailability {
    try {
        $null = Get-Command docker -ErrorAction Stop
    }
    catch {
        Write-ColoredOutput "Docker is not installed or not in PATH" -Type Error
        Write-ColoredOutput "Please install Docker Desktop from: https://docs.docker.com/desktop/install/windows/" -Type Info
        exit 1
    }
    
    try {
        $null = docker info 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Docker not running"
        }
    }
    catch {
        Write-ColoredOutput "Docker is not running or you don't have permission to use it" -Type Error
        Write-ColoredOutput "Please start Docker Desktop" -Type Info
        exit 1
    }
}

# Function to pull latest image
function Update-ContainerImage {
    if (-not $NoPull) {
        Write-ColoredOutput "Pulling latest ARI container image: $Image" -Type Info
        docker pull $Image 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-ColoredOutput "Failed to pull image. Using local image if available." -Type Warning
        }
    }
}

# Function to validate image exists
function Test-ContainerImage {
    docker image inspect $Image >$null 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-ColoredOutput "Container image '$Image' not found" -Type Error
        Write-ColoredOutput "Please build the image first or use -Image to specify a different image" -Type Info
        Write-ColoredOutput "To build: docker build -t ari:latest containers/runtime/" -Type Info
        exit 1
    }
}

# Show help if requested
if ($Help) {
    Show-DetailedHelp
    exit 0
}

# Enable debug output if requested
if ($Debug) {
    $DebugPreference = 'Continue'
}

Write-ColoredOutput "Starting Azure Resource Inventory container runner" -Type Info

# Check prerequisites
Test-DockerAvailability

# Pull or check image
if ($NoPull) {
    Test-ContainerImage
} else {
    Update-ContainerImage
}

# Resolve and create output directory
$OutputPath = Resolve-Path $OutputPath -ErrorAction SilentlyContinue
if (-not $OutputPath) {
    $OutputPath = $PSScriptRoot + "\ari-output"
}

Write-ColoredOutput "Creating output directory: $OutputPath" -Type Info
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Convert Windows path to Docker format
$DockerOutputPath = $OutputPath -replace '\\', '/' -replace '^([A-Za-z]):', '/mnt/$1'
if ($OutputPath -match '^[A-Za-z]:') {
    $DockerOutputPath = $OutputPath -replace '\\', '/' -replace '^([A-Za-z]):', '/$1'
}

# Prepare Docker run command
$DockerArgs = @(
    'run', '--rm', '-it',
    '-v', "${OutputPath}:/ari-output"
)

# Add environment variables for service principal if needed
if ($ServicePrincipal) {
    Write-ColoredOutput "Using service principal authentication" -Type Info
    Write-ColoredOutput "Ensure AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, and AZURE_TENANT_ID are set" -Type Info
    $DockerArgs += '-e', 'AZURE_CLIENT_ID', '-e', 'AZURE_CLIENT_SECRET', '-e', 'AZURE_TENANT_ID'
}

# Mount Azure config if requested
if ($MountAzureConfig -and (Test-Path "$env:USERPROFILE\.azure")) {
    Write-ColoredOutput "Mounting Azure configuration from ~/.azure" -Type Info
    $AzureConfigPath = "$env:USERPROFILE\.azure" -replace '\\', '/'
    $DockerArgs += '-v', "${AzureConfigPath}:/home/ariuser/.azure:ro"
}

# Add the image
$DockerArgs += $Image

# Build ARI parameters
$AriParams = @()

if ($TenantId) { $AriParams += '-TenantID', $TenantId }
if ($SubscriptionId) { $AriParams += '-SubscriptionID', $SubscriptionId }
if ($ResourceGroup) { $AriParams += '-ResourceGroup', $ResourceGroup }
if ($IncludeTags) { $AriParams += '-IncludeTags' }
if ($SecurityCenter) { $AriParams += '-SecurityCenter' }
if ($SkipAdvisory) { $AriParams += '-SkipAdvisory' }
if ($ReportName) { $AriParams += '-ReportName', $ReportName }
if ($Lite) { $AriParams += '-Lite' }
if ($DeviceLogin) { $AriParams += '-DeviceLogin' }

# Add any additional parameters
if ($AdditionalParams) {
    $AriParams += $AdditionalParams
}

# Build the PowerShell command
$PowerShellCmd = "Import-Module /opt/ari/AzureResourceInventory.psm1; Invoke-ARI"
if ($AriParams.Count -gt 0) {
    $PowerShellCmd += " " + ($AriParams -join " ")
}

# Add the PowerShell command to Docker args
$DockerArgs += 'pwsh', '-c', $PowerShellCmd

Write-ColoredOutput "Running ARI with parameters: $($AriParams -join ' ')" -Type Info
Write-ColoredOutput "Output will be saved to: $OutputPath" -Type Info

# Execute the Docker command
if ($Debug) {
    Write-ColoredOutput "Docker command: docker $($DockerArgs -join ' ')" -Type Info
}

try {
    & docker @DockerArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColoredOutput "ARI execution completed successfully!" -Type Success
        Write-ColoredOutput "Reports are available in: $OutputPath" -Type Info
        
        # Show generated files
        $GeneratedFiles = Get-ChildItem $OutputPath -Filter "*.xlsx" | Sort-Object LastWriteTime -Descending
        if ($GeneratedFiles) {
            Write-ColoredOutput "Generated reports:" -Type Info
            foreach ($file in $GeneratedFiles) {
                Write-Host "  - $($file.Name)" -ForegroundColor Gray
            }
        }
    } else {
        Write-ColoredOutput "ARI execution failed" -Type Error
        exit 1
    }
}
catch {
    Write-ColoredOutput "Failed to execute Docker command: $($_.Exception.Message)" -Type Error
    exit 1
}