<#
.SYNOPSIS
    Validates the Azure Resource Inventory development environment
    
.DESCRIPTION
    This script validates that all required components are properly installed
    and configured in the development environment, including PowerShell modules,
    Azure CLI, and other dependencies.
    
.EXAMPLE
    ./scripts/validate-environment.ps1
    
.NOTES
    This script is designed to run in the ARI DevContainer environment
#>

[CmdletBinding()]
param()

# Set error action preference
$ErrorActionPreference = 'Stop'

# Function to write colored output
function Write-ColoredOutput {
    param(
        [string]$Message,
        [ValidateSet('Green', 'Red', 'Yellow', 'Cyan', 'White')]
        [string]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to check if a module is available
function Test-ModuleAvailability {
    param(
        [string]$ModuleName,
        [string]$MinimumVersion = $null
    )
    
    try {
        $module = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1
        if ($module) {
            if ($MinimumVersion -and $module.Version -lt [version]$MinimumVersion) {
                return @{
                    Available = $false
                    Version = $module.Version
                    Message = "Version $($module.Version) is below minimum required version $MinimumVersion"
                }
            }
            return @{
                Available = $true
                Version = $module.Version
                Message = "Available (Version: $($module.Version))"
            }
        } else {
            return @{
                Available = $false
                Version = $null
                Message = "Not installed"
            }
        }
    } catch {
        return @{
            Available = $false
            Version = $null
            Message = "Error checking module: $($_.Exception.Message)"
        }
    }
}

# Function to check if a command is available
function Test-CommandAvailability {
    param(
        [string]$CommandName
    )
    
    try {
        $command = Get-Command -Name $CommandName -ErrorAction SilentlyContinue
        if ($command) {
            return @{
                Available = $true
                Path = $command.Source
                Message = "Available at: $($command.Source)"
            }
        } else {
            return @{
                Available = $false
                Path = $null
                Message = "Not found in PATH"
            }
        }
    } catch {
        return @{
            Available = $false
            Path = $null
            Message = "Error checking command: $($_.Exception.Message)"
        }
    }
}

# Start validation
Write-ColoredOutput "=====================================" "Cyan"
Write-ColoredOutput "ARI Development Environment Validation" "Cyan"
Write-ColoredOutput "=====================================" "Cyan"
Write-Host ""

# Check PowerShell version
Write-ColoredOutput "Checking PowerShell Environment..." "Yellow"
$psVersion = $PSVersionTable.PSVersion
Write-Host "  PowerShell Version: $psVersion" -ForegroundColor White

if ($psVersion.Major -ge 7) {
    Write-ColoredOutput "  ✓ PowerShell 7+ detected" "Green"
} elseif ($psVersion.Major -eq 5 -and $psVersion.Minor -ge 1) {
    Write-ColoredOutput "  ⚠ PowerShell 5.1 detected (minimum supported)" "Yellow"
} else {
    Write-ColoredOutput "  ✗ PowerShell version too old (minimum: 5.1)" "Red"
}

Write-Host ""

# Check required PowerShell modules
Write-ColoredOutput "Checking Required PowerShell Modules..." "Yellow"
$requiredModules = @(
    @{ Name = "ImportExcel"; MinVersion = $null },
    @{ Name = "Az.Accounts"; MinVersion = $null },
    @{ Name = "Az.ResourceGraph"; MinVersion = $null },
    @{ Name = "Az.Storage"; MinVersion = $null },
    @{ Name = "Az.Compute"; MinVersion = $null },
    @{ Name = "Az.CostManagement"; MinVersion = $null },
    @{ Name = "PSScriptAnalyzer"; MinVersion = $null },
    @{ Name = "Pester"; MinVersion = $null }
)

$moduleIssues = 0
foreach ($module in $requiredModules) {
    $result = Test-ModuleAvailability -ModuleName $module.Name -MinimumVersion $module.MinVersion
    if ($result.Available) {
        Write-ColoredOutput "  ✓ $($module.Name): $($result.Message)" "Green"
    } else {
        Write-ColoredOutput "  ✗ $($module.Name): $($result.Message)" "Red"
        $moduleIssues++
    }
}

Write-Host ""

# Check Azure CLI
Write-ColoredOutput "Checking Azure CLI..." "Yellow"
$azResult = Test-CommandAvailability -CommandName "az"
if ($azResult.Available) {
    try {
        $azVersion = az version --output tsv --query '"azure-cli"' 2>$null
        Write-ColoredOutput "  ✓ Azure CLI: Available (Version: $azVersion)" "Green"
    } catch {
        Write-ColoredOutput "  ✓ Azure CLI: Available (Version check failed)" "Green"
    }
} else {
    Write-ColoredOutput "  ✗ Azure CLI: $($azResult.Message)" "Red"
}

Write-Host ""

# Check Git
Write-ColoredOutput "Checking Git..." "Yellow"
$gitResult = Test-CommandAvailability -CommandName "git"
if ($gitResult.Available) {
    try {
        $gitVersion = git --version
        Write-ColoredOutput "  ✓ Git: Available ($gitVersion)" "Green"
    } catch {
        Write-ColoredOutput "  ✓ Git: Available (Version check failed)" "Green"
    }
} else {
    Write-ColoredOutput "  ✗ Git: $($gitResult.Message)" "Red"
}

Write-Host ""

# Check execution policy
Write-ColoredOutput "Checking PowerShell Execution Policy..." "Yellow"
$executionPolicy = Get-ExecutionPolicy
Write-Host "  Current Execution Policy: $executionPolicy" -ForegroundColor White

if ($executionPolicy -in @('RemoteSigned', 'Unrestricted', 'Bypass')) {
    Write-ColoredOutput "  ✓ Execution policy allows script execution" "Green"
} else {
    Write-ColoredOutput "  ⚠ Execution policy may prevent script execution" "Yellow"
}

Write-Host ""

# Check if ARI module can be loaded
Write-ColoredOutput "Checking ARI Module..." "Yellow"
$workspaceFolder = $env:WORKSPACE_FOLDER
if (-not $workspaceFolder) {
    $workspaceFolder = "/workspace"
}

$ariModulePath = Join-Path $workspaceFolder "AzureResourceInventory.psm1"
if (Test-Path $ariModulePath) {
    try {
        Import-Module $ariModulePath -Force -ErrorAction Stop
        Write-ColoredOutput "  ✓ ARI module loaded successfully" "Green"
        
        # Check if main function is available
        if (Get-Command -Name "Invoke-ARI" -ErrorAction SilentlyContinue) {
            Write-ColoredOutput "  ✓ Invoke-ARI function is available" "Green"
        } else {
            Write-ColoredOutput "  ✗ Invoke-ARI function not found" "Red"
        }
    } catch {
        Write-ColoredOutput "  ✗ Failed to load ARI module: $($_.Exception.Message)" "Red"
    }
} else {
    Write-ColoredOutput "  ✗ ARI module not found at: $ariModulePath" "Red"
}

Write-Host ""

# Summary
Write-ColoredOutput "=====================================" "Cyan"
Write-ColoredOutput "Validation Summary" "Cyan"
Write-ColoredOutput "=====================================" "Cyan"

if ($moduleIssues -eq 0) {
    Write-ColoredOutput "✓ All required PowerShell modules are available" "Green"
} else {
    Write-ColoredOutput "✗ $moduleIssues PowerShell modules are missing or have issues" "Red"
}

if ($azResult.Available -and $gitResult.Available) {
    Write-ColoredOutput "✓ All required command-line tools are available" "Green"
} else {
    Write-ColoredOutput "✗ Some command-line tools are missing" "Red"
}

Write-Host ""

if ($moduleIssues -eq 0 -and $azResult.Available -and $gitResult.Available) {
    Write-ColoredOutput "🎉 Environment validation completed successfully!" "Green"
    Write-ColoredOutput "Your development environment is ready for ARI development." "Green"
} else {
    Write-ColoredOutput "⚠ Environment validation completed with issues." "Yellow"
    Write-ColoredOutput "Please resolve the issues above before proceeding with development." "Yellow"
}

Write-Host ""
Write-ColoredOutput "Next Steps:" "Cyan"
Write-ColoredOutput "1. Import the ARI module: Import-Module ./AzureResourceInventory.psm1" "White"
Write-ColoredOutput "2. Authenticate with Azure: Connect-AzAccount" "White"
Write-ColoredOutput "3. Run your first inventory: Invoke-ARI" "White"
Write-Host ""