#!/bin/bash
#
# Azure Resource Inventory - Container Wrapper Script
# Simplifies running ARI in a Docker container for enterprise environments
#
# Usage: ./run-ari.sh [ARI_OPTIONS]
#
# This script bypasses local PowerShell restrictions by running ARI in a container
#

set -e

# Script version
SCRIPT_VERSION="1.0.0"
ARI_IMAGE="ari:latest"
DEFAULT_OUTPUT_DIR="./ari-output"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show help
show_help() {
    echo "Azure Resource Inventory - Container Runner v${SCRIPT_VERSION}"
    echo ""
    echo "This script runs ARI in a Docker container to bypass PowerShell restrictions."
    echo ""
    echo "Usage: $0 [OPTIONS] [ARI_PARAMETERS]"
    echo ""
    echo "Container Options:"
    echo "  -h, --help              Show this help message"
    echo "  -v, --version           Show version information"
    echo "  -i, --image IMAGE       Use specific ARI container image (default: ${ARI_IMAGE})"
    echo "  -o, --output DIR        Output directory (default: ${DEFAULT_OUTPUT_DIR})"
    echo "  --no-pull              Don't pull latest image before running"
    echo "  --debug                Enable debug output"
    echo ""
    echo "Azure Authentication Options:"
    echo "  --device-login         Use device code authentication (default)"
    echo "  --service-principal    Use service principal (requires env vars)"
    echo "  --mount-azure-config   Mount ~/.azure directory from host"
    echo ""
    echo "Common ARI Parameters:"
    echo "  --tenant-id ID         Azure tenant ID"
    echo "  --subscription-id ID   Azure subscription ID"
    echo "  --resource-group RG    Limit to specific resource group"
    echo "  --include-tags         Include resource tags in report"
    echo "  --security-center      Include Security Center data"
    echo "  --skip-advisory        Skip Azure Advisory data"
    echo "  --report-name NAME     Custom report name"
    echo "  --lite                 Generate lightweight report"
    echo ""
    echo "Examples:"
    echo "  # Basic usage with device login"
    echo "  $0 --tenant-id 12345678-1234-1234-1234-123456789012"
    echo ""
    echo "  # Specific subscription with tags"
    echo "  $0 --tenant-id 12345678-1234-1234-1234-123456789012 --subscription-id abcd-efgh --include-tags"
    echo ""
    echo "  # Custom output directory and report name"
    echo "  $0 -o ./reports --report-name MyCompanyInventory --tenant-id 12345678-1234-1234-1234-123456789012"
    echo ""
    echo "For complete ARI parameter documentation:"
    echo "  docker run --rm ${ARI_IMAGE} pwsh -c \"Import-Module /opt/ari/AzureResourceInventory.psm1; Get-Help Invoke-ARI -Full\""
}

# Function to check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        print_info "Please install Docker Desktop from: https://docs.docker.com/get-docker/"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        print_error "Docker is not running or you don't have permission to use it"
        print_info "Please start Docker Desktop or add your user to the docker group"
        exit 1
    fi
}

# Function to pull latest image if needed
pull_image() {
    if [ "$NO_PULL" != "true" ]; then
        print_info "Pulling latest ARI container image: ${ARI_IMAGE}"
        if ! docker pull "${ARI_IMAGE}" 2>/dev/null; then
            print_warning "Failed to pull image. Using local image if available."
        fi
    fi
}

# Function to validate image exists
check_image() {
    if ! docker image inspect "${ARI_IMAGE}" &> /dev/null; then
        print_error "Container image '${ARI_IMAGE}' not found"
        print_info "Please build the image first or use --image to specify a different image"
        print_info "To build: docker build -t ari:latest containers/runtime/"
        exit 1
    fi
}

# Parse command line arguments
OUTPUT_DIR="${DEFAULT_OUTPUT_DIR}"
NO_PULL="false"
DEBUG="false"
MOUNT_AZURE_CONFIG="false"
ARI_PARAMS=()
DOCKER_ENV_VARS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            echo "run-ari.sh version ${SCRIPT_VERSION}"
            exit 0
            ;;
        -i|--image)
            ARI_IMAGE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --no-pull)
            NO_PULL="true"
            shift
            ;;
        --debug)
            DEBUG="true"
            shift
            ;;
        --device-login)
            # Default auth method, no special handling needed
            ARI_PARAMS+=("$1")
            shift
            ;;
        --service-principal)
            print_info "Using service principal authentication"
            print_info "Ensure AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, and AZURE_TENANT_ID are set"
            DOCKER_ENV_VARS+=("-e" "AZURE_CLIENT_ID" "-e" "AZURE_CLIENT_SECRET" "-e" "AZURE_TENANT_ID")
            ARI_PARAMS+=("$1")
            shift
            ;;
        --mount-azure-config)
            MOUNT_AZURE_CONFIG="true"
            shift
            ;;
        *)
            # Pass all other arguments to ARI
            ARI_PARAMS+=("$1")
            shift
            ;;
    esac
done

# Enable debug output if requested
if [ "$DEBUG" = "true" ]; then
    set -x
fi

print_info "Starting Azure Resource Inventory container runner"

# Check prerequisites
check_docker

# Pull or check image
if [ "$NO_PULL" = "true" ]; then
    check_image
else
    pull_image
fi

# Create output directory
print_info "Creating output directory: ${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

# Prepare Docker run command
DOCKER_CMD=(
    "docker" "run" "--rm" "-it"
    "-v" "${OUTPUT_DIR}:/ari-output"
)

# Add environment variables if needed
if [ ${#DOCKER_ENV_VARS[@]} -gt 0 ]; then
    DOCKER_CMD+=("${DOCKER_ENV_VARS[@]}")
fi

# Mount Azure config if requested
if [ "$MOUNT_AZURE_CONFIG" = "true" ] && [ -d "${HOME}/.azure" ]; then
    print_info "Mounting Azure configuration from ~/.azure"
    DOCKER_CMD+=("-v" "${HOME}/.azure:/home/ariuser/.azure:ro")
fi

# Add the image
DOCKER_CMD+=("${ARI_IMAGE}")

# Build the PowerShell command
POWERSHELL_CMD="Import-Module /opt/ari/AzureResourceInventory.psm1; Invoke-ARI"

# Add ARI parameters if any
if [ ${#ARI_PARAMS[@]} -gt 0 ]; then
    for param in "${ARI_PARAMS[@]}"; do
        POWERSHELL_CMD+=" $param"
    done
fi

# Add the PowerShell command
DOCKER_CMD+=("pwsh" "-c" "${POWERSHELL_CMD}")

print_info "Running ARI with parameters: ${ARI_PARAMS[*]}"
print_info "Output will be saved to: ${OUTPUT_DIR}"

# Execute the Docker command
if [ "$DEBUG" = "true" ]; then
    print_info "Docker command: ${DOCKER_CMD[*]}"
fi

"${DOCKER_CMD[@]}"

# Check if execution was successful
if [ $? -eq 0 ]; then
    print_success "ARI execution completed successfully!"
    print_info "Reports are available in: ${OUTPUT_DIR}"
else
    print_error "ARI execution failed"
    exit 1
fi