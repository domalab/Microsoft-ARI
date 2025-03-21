# Test script for ARI local code
Write-Host "Testing ARI local code from repository..." -ForegroundColor Cyan

# Create a log file for the test
$LogFile = "$PSScriptRoot\ARI-Test-Log.txt"
"ARI Test Log - $(Get-Date)" | Out-File -FilePath $LogFile -Force

# Load required functions
try {
    # Check for Azure module
    if (-not (Get-Module -Name Az -ListAvailable)) {
        Write-Host "Azure PowerShell module not found. Installing..." -ForegroundColor Yellow
        Install-Module -Name Az -Scope CurrentUser -Force
    }
    
    # Import Azure modules if not already loaded
    if (-not (Get-Module -Name Az.Accounts)) {
        Import-Module Az.Accounts -ErrorAction Stop
    }
    
    Write-Host "Checking Azure connection..." -ForegroundColor Cyan
    try {
        $context = Get-AzContext -ErrorAction Stop
        if ($context) {
            Write-Host "Connected to Azure as: $($context.Account.Id)" -ForegroundColor Green
            Write-Host "Current subscription: $($context.Subscription.Name)" -ForegroundColor Green
        } else {
            Write-Host "Not connected to Azure. Please connect first." -ForegroundColor Yellow
            Connect-AzAccount
        }
    }
    catch {
        Write-Host "Not connected to Azure. Please connect first." -ForegroundColor Yellow
        Connect-AzAccount
    }
    
    # Try to run Invoke-ARI with minimal parameters to test functionality
    Write-Host "`nAttempting to run ARI with local modifications..." -ForegroundColor Cyan
    Write-Host "This will only execute the command with -Debug parameter to verify it can run" -ForegroundColor Yellow
    
    # Load the module directly from local path
    Write-Host "Loading module from local path..." -ForegroundColor Cyan
    Import-Module "$PSScriptRoot\AzureResourceInventory.psd1" -Force -ErrorAction Stop
    
    # Run ARI in debug mode
    Write-Host "Running ARI in debug mode..." -ForegroundColor Cyan
    Invoke-ARI -Debug -Lite -SkipDiagram
    
    Write-Host "`nTest completed successfully. Your local ARI code appears to be working." -ForegroundColor Green
    
} catch {
    Write-Host "Error testing ARI local code: $_" -ForegroundColor Red
    $_ | Out-File -FilePath $LogFile -Append
}
