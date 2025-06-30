@echo off
REM Azure Resource Inventory - Simple Windows Batch Wrapper
REM For users who cannot run PowerShell scripts due to execution policy restrictions
REM
REM Usage: run-ari.bat [tenant-id] [subscription-id] [additional-params...]
REM
REM This is a minimal wrapper - for advanced options use run-ari.ps1

setlocal enabledelayedexpansion

REM Script configuration
set ARI_IMAGE=ari:latest
set OUTPUT_DIR=%cd%\ari-output

REM Color codes for output
set COLOR_INFO=96
set COLOR_SUCCESS=92
set COLOR_WARNING=93
set COLOR_ERROR=91

echo.
echo [96mAzure Resource Inventory - Container Runner[0m
echo [96mSimple batch interface for enterprise environments[0m
echo.

REM Check if Docker is available
docker --version >nul 2>&1
if errorlevel 1 (
    echo [91m[ERROR][0m Docker is not installed or not in PATH
    echo [96m[INFO][0m Please install Docker Desktop from: https://docs.docker.com/desktop/install/windows/
    exit /b 1
)

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo [91m[ERROR][0m Docker is not running
    echo [96m[INFO][0m Please start Docker Desktop
    exit /b 1
)

REM Show help if no parameters or help requested
if "%1"=="" goto show_help
if "%1"=="-h" goto show_help
if "%1"=="--help" goto show_help
if "%1"=="/?" goto show_help

REM Parse basic parameters
set TENANT_ID=%1
set SUBSCRIPTION_ID=%2

REM Shift to get additional parameters
shift
shift
set ADDITIONAL_PARAMS=
:parse_additional
if "%1"=="" goto done_parsing
set ADDITIONAL_PARAMS=%ADDITIONAL_PARAMS% %1
shift
goto parse_additional
:done_parsing

REM Validate tenant ID
if "%TENANT_ID%"=="" (
    echo [91m[ERROR][0m Tenant ID is required
    echo [96m[INFO][0m Usage: %0 [tenant-id] [subscription-id] [additional-params...]
    exit /b 1
)

echo [96m[INFO][0m Pulling latest ARI container image...
docker pull %ARI_IMAGE% >nul 2>&1
if errorlevel 1 (
    echo [93m[WARNING][0m Failed to pull image. Using local image if available.
)

REM Create output directory
echo [96m[INFO][0m Creating output directory: %OUTPUT_DIR%
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Build Docker command
set DOCKER_CMD=docker run --rm -it -v "%OUTPUT_DIR%:/ari-output" %ARI_IMAGE%

REM Build PowerShell command
set PS_CMD=Import-Module /opt/ari/AzureResourceInventory.psm1; Invoke-ARI -TenantID %TENANT_ID%

REM Add subscription ID if provided
if not "%SUBSCRIPTION_ID%"=="" (
    set PS_CMD=%PS_CMD% -SubscriptionID %SUBSCRIPTION_ID%
)

REM Add additional parameters
if not "%ADDITIONAL_PARAMS%"=="" (
    set PS_CMD=%PS_CMD% %ADDITIONAL_PARAMS%
)

echo [96m[INFO][0m Running ARI with Tenant ID: %TENANT_ID%
if not "%SUBSCRIPTION_ID%"=="" echo [96m[INFO][0m Subscription ID: %SUBSCRIPTION_ID%
echo [96m[INFO][0m Output will be saved to: %OUTPUT_DIR%
echo.

REM Execute the Docker command
%DOCKER_CMD% pwsh -c "%PS_CMD%"

if errorlevel 1 (
    echo.
    echo [91m[ERROR][0m ARI execution failed
    exit /b 1
) else (
    echo.
    echo [92m[SUCCESS][0m ARI execution completed successfully!
    echo [96m[INFO][0m Reports are available in: %OUTPUT_DIR%
    
    REM List generated files
    echo [96m[INFO][0m Generated files:
    for %%f in ("%OUTPUT_DIR%\*.xlsx") do echo   - %%~nxf
)

goto end

:show_help
echo Usage: %0 [tenant-id] [subscription-id] [additional-parameters...]
echo.
echo This is a simple batch wrapper for running ARI in a Docker container.
echo It bypasses local PowerShell restrictions by running in an isolated container.
echo.
echo Parameters:
echo   tenant-id              Azure tenant ID (required)
echo   subscription-id        Azure subscription ID (optional)
echo   additional-parameters  Any additional ARI parameters
echo.
echo Examples:
echo   %0 12345678-1234-1234-1234-123456789012
echo   %0 12345678-1234-1234-1234-123456789012 abcd-efgh-ijkl
echo   %0 12345678-1234-1234-1234-123456789012 "" -IncludeTags -SecurityCenter
echo.
echo For advanced options and authentication methods, use run-ari.ps1 instead.
echo.
echo For complete ARI parameter documentation:
echo   docker run --rm %ARI_IMAGE% pwsh -c "Import-Module /opt/ari/AzureResourceInventory.psm1; Get-Help Invoke-ARI -Full"

:end
endlocal