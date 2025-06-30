# DevContainer Setup Guide

This guide provides detailed instructions for setting up and using the DevContainer environment for Azure Resource Inventory (ARI) development.

## What is a DevContainer?

A DevContainer (Development Container) is a Docker-based development environment that provides a consistent, reproducible setup across different machines and operating systems. It includes all the tools, libraries, and configurations needed for ARI development.

## Prerequisites

Before using the DevContainer, ensure you have:

- [Visual Studio Code](https://code.visualstudio.com/) installed
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) for VS Code

## Quick Start

1. **Clone the Repository**
   ```bash
   git clone https://github.com/microsoft/ARI.git
   cd ARI
   ```

2. **Open in VS Code**
   ```bash
   code .
   ```

3. **Reopen in Container**
   - VS Code should automatically detect the DevContainer configuration
   - Click "Reopen in Container" when prompted, or
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac) and select "Dev Containers: Reopen in Container"

4. **Wait for Build**
   - First-time setup takes ~5-10 minutes to download and build
   - Subsequent starts are much faster

5. **Validate Environment**
   - The container will automatically run validation scripts
   - You can manually validate by running: `./scripts/validate-environment.ps1`

## What's Included

The DevContainer includes:

### Development Tools
- PowerShell 7.4
- Azure CLI
- Git
- Visual Studio Code extensions for PowerShell and Azure

### PowerShell Modules
- **ImportExcel** - Excel file generation
- **Az.Accounts** - Azure authentication
- **Az.ResourceGraph** - Resource querying
- **Az.Storage** - Storage account operations
- **Az.Compute** - Compute resource management
- **Az.CostManagement** - Cost analysis
- **PSScriptAnalyzer** - Code quality analysis
- **Pester** - Testing framework

### VS Code Extensions
- PowerShell extension with IntelliSense
- Azure development tools
- GitLens for enhanced Git experience
- Docker support
- Spell checker and productivity tools

## Working in the DevContainer

### Terminal Access
- The integrated terminal in VS Code runs PowerShell 7.4 by default
- All required modules are pre-loaded and ready to use

### File Editing
- All files are automatically synchronized between your local machine and the container
- Changes persist even when the container is rebuilt

### Azure Authentication
- Your local Azure CLI configuration is mounted into the container
- Run `Connect-AzAccount` to authenticate with Azure PowerShell modules
- Use `az login` for Azure CLI authentication

### Testing Changes
- Import the ARI module: `Import-Module ./AzureResourceInventory.psm1`
- Run validation: `./scripts/validate-environment.ps1`
- Test functionality: `Invoke-ARI -Debug`

## Common Tasks

### Starting Development
```powershell
# Import the ARI module
Import-Module ./AzureResourceInventory.psm1

# Authenticate with Azure
Connect-AzAccount

# Validate your environment
./scripts/validate-environment.ps1

# Start developing!
```

### Running Tests
```powershell
# Run PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path ./ -Recurse

# Run custom validation
./scripts/validate-environment.ps1
```

### Adding New Dependencies
If you need to add new PowerShell modules:

1. Update the Dockerfile in `.devcontainer/Dockerfile`
2. Add the new module installation command
3. Rebuild the container: `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"

## Troubleshooting

### Container Won't Start
- Ensure Docker Desktop is running
- Check available disk space (containers need ~2-3GB)
- Try rebuilding: `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"

### Slow Performance
- Close unnecessary applications to free up resources
- Increase Docker Desktop memory allocation (Settings → Resources → Memory)
- Consider using Docker Desktop with WSL2 backend on Windows

### Module Loading Issues
- Run the validation script: `./scripts/validate-environment.ps1`
- Try rebuilding the container if modules are missing
- Check the container logs for installation errors

### Azure Authentication Issues
- Ensure your local `~/.azure` directory exists and contains valid credentials
- Try running `az account clear` and `az login` to refresh authentication
- For PowerShell modules, use `Connect-AzAccount` separately

### File Permission Issues
- The container runs as a non-root user (`vscode`)
- If you encounter permission issues, try: `sudo chown -R vscode:vscode /workspace`

## Advanced Usage

### Custom Configuration
You can customize the DevContainer by modifying:
- `.devcontainer/devcontainer.json` - Main configuration
- `.devcontainer/Dockerfile` - Container image definition

### Multiple Terminals
- Open multiple PowerShell terminals for parallel development tasks
- Each terminal maintains the same environment and loaded modules

### Debugging
- Use the PowerShell debugger with F5 or set breakpoints
- VS Code debugging is fully configured for PowerShell scripts

### Port Forwarding
The DevContainer supports port forwarding for web-based tools:
```json
"forwardPorts": [8080, 3000]
```

## Benefits of Using DevContainers

### Consistency
- Same environment across all development machines
- Identical PowerShell and module versions
- Consistent tooling and configuration

### Isolation
- No conflicts with local PowerShell installations
- Clean environment for each project
- Easy to reset if something goes wrong

### Cross-Platform
- Works identically on Windows, macOS, and Linux
- No need to manage different installation procedures

### Team Collaboration
- New team members can start contributing immediately
- Reduces "works on my machine" issues
- Standardized development workflows

## Next Steps

Once your DevContainer is running:

1. Read the [Contributing Guide](contributing.md) for development guidelines
2. Explore the [Module Structure](module-structure.md) to understand the codebase
3. Check out the [Quick Start Guide](../getting-started/quick-start.md) to run your first inventory

## Getting Help

If you encounter issues with the DevContainer setup:

1. Check this troubleshooting section first
2. Look for existing issues in the [GitHub repository](https://github.com/microsoft/ARI/issues)
3. Create a new issue with details about your environment and the problem
4. Include logs from the container build process if applicable