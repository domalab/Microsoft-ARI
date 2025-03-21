# Script to run the local ARI code
# Created for testing and running local version of ARI

Write-Host "Azure Resource Inventory (ARI) Local Runner" -ForegroundColor Cyan
Write-Host "===========================================`n" -ForegroundColor Cyan

# Set the execution directory to the repository root
$RepoRoot = $PSScriptRoot
Set-Location $RepoRoot

# Check if Azure module is installed and load it
if (-not (Get-Module -Name Az -ListAvailable)) {
    Write-Host "Azure PowerShell module not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name Az -Scope CurrentUser -Force -AllowClobber
}

# Create a log directory if it doesn't exist
$LogDir = "$RepoRoot\Logs"
if (-not (Test-Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
}

$LogFile = "$LogDir\ARI-Local-Run-$(Get-Date -Format 'yyyy-MM-dd_HH_mm_ss').log"
"ARI Local Run Log - Started: $(Get-Date)" | Out-File -FilePath $LogFile

# Function to test if a file has syntax errors
function Test-ScriptSyntax {
    param (
        [string]$FilePath
    )
    
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$null, [ref]$errors)
    
    if ($errors) {
        Write-Host "Syntax errors found in $FilePath:" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "  Line $($error.Extent.StartLineNumber): $($error.Message)" -ForegroundColor Red
        }
        return $false
    }
    
    return $true
}

# Test key files for syntax errors
$filesToCheck = @(
    "$RepoRoot\Modules\Public\PublicFunctions\Diagram\Build-ARIDiagramSubnet.ps1",
    "$RepoRoot\Modules\Public\PublicFunctions\Diagram\Start-ARIDiagramNetwork.ps1",
    "$RepoRoot\Modules\Private\1.ExtractionFunctions\Get-ARIAPIResources.ps1"
)

$allFilesValid = $true
foreach ($file in $filesToCheck) {
    Write-Host "Checking syntax for $file..." -ForegroundColor Yellow
    if (-not (Test-ScriptSyntax -FilePath $file)) {
        $allFilesValid = $false
    } else {
        Write-Host "  ✓ Syntax looks good" -ForegroundColor Green
    }
}

if (-not $allFilesValid) {
    Write-Host "`nSyntax errors were found in one or more files. Please fix these errors before running ARI." -ForegroundColor Red
    Write-Host "You can find details in the log file: $LogFile" -ForegroundColor Yellow
    return
}

# Try to check Azure connection
Write-Host "`nChecking Azure connection..." -ForegroundColor Cyan
try {
    $context = Get-AzContext -ErrorAction Stop
    if ($context) {
        Write-Host "Connected to Azure as: $($context.Account.Id)" -ForegroundColor Green
        Write-Host "Current subscription: $($context.Subscription.Name)" -ForegroundColor Green
    } else {
        Write-Host "Not connected to Azure. Connecting now..." -ForegroundColor Yellow
        Connect-AzAccount
    }
}
catch {
    Write-Host "Not connected to Azure. Connecting now..." -ForegroundColor Yellow
    Connect-AzAccount
}

# Load the ARI module from the local path
Write-Host "`nLoading ARI module from local repository..." -ForegroundColor Cyan
try {
    # First unload any existing instance of the module
    if (Get-Module -Name AzureResourceInventory) {
        Remove-Module -Name AzureResourceInventory -Force -ErrorAction SilentlyContinue
    }
    
    # Import the module
    Import-Module "$RepoRoot\AzureResourceInventory.psd1" -Force -ErrorAction Stop
    Write-Host "Successfully loaded the ARI module from local repository" -ForegroundColor Green
    
    # Show the available commands
    Write-Host "`nAvailable commands from ARI:" -ForegroundColor Cyan
    Get-Command -Module AzureResourceInventory | Format-Table -AutoSize
    
    # Ask for parameters
    Write-Host "`nRunning ARI with local code. Please provide the parameters:" -ForegroundColor Cyan
    
    # Get current tenant ID from Azure context
    $context = Get-AzContext
    $defaultTenantId = $context.Tenant.Id
    Write-Host "Current Tenant ID: $defaultTenantId" -ForegroundColor Green
    
    $tenantId = Read-Host "Enter Tenant ID (press Enter to use current tenant)"
    if ([string]::IsNullOrEmpty($tenantId)) {
        $tenantId = $defaultTenantId
    }
    
    $generateDiagram = Read-Host "Generate network diagram? (Y/N)"
    $diagramParam = if ($generateDiagram -eq "Y") { $true } else { $false }
    
    $advancedFeatures = Read-Host "Enable advanced features (Security Center, Policy, Advisor)? (Y/N)"
    $advancedParam = if ($advancedFeatures -eq "Y") { $true } else { $false }
    
    $reportPath = Read-Host "Report path (leave empty for default C:\AzureResourceInventory)"
    if ([string]::IsNullOrWhiteSpace($reportPath)) {
        $reportPath = "C:\AzureResourceInventory"
    }
    
    # Run ARI
    Write-Host "`nRunning ARI with the following parameters:" -ForegroundColor Cyan
    Write-Host "  Tenant ID: $tenantId" -ForegroundColor Yellow
    Write-Host "  Generate Diagram: $diagramParam" -ForegroundColor Yellow
    Write-Host "  Advanced Features: $advancedParam" -ForegroundColor Yellow
    Write-Host "  Report Path: $reportPath" -ForegroundColor Yellow
    
    Write-Host "`nStarting ARI now..." -ForegroundColor Green
    
    $params = @{
        TenantID = $tenantId
        SkipDiagram = (-not $diagramParam)
        SecurityCenter = $advancedParam
        Advisory = $advancedParam
        ReportPath = $reportPath
    }
    
    Invoke-ARI @params
    
    Write-Host "`nARI execution completed. Check the report at: $reportPath" -ForegroundColor Green
}
catch {
    Write-Host "Error loading or running ARI: $_" -ForegroundColor Red
    $_ | Out-File -FilePath $LogFile -Append
}

Write-Host "`nScript execution completed. Log file: $LogFile" -ForegroundColor Cyan
