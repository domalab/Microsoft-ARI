# Contributing to Azure Resource Inventory

Thank you for your interest in contributing to Azure Resource Inventory! This guide will help you get started with contributing to the project.

## Ways to Contribute

There are many ways to contribute to Azure Resource Inventory:

- Report bugs and issues
- Suggest new features or improvements
- Improve documentation
- Submit pull requests with code changes
- Share your experiences using ARI

## Getting Started

### Prerequisites

To contribute to the codebase, you'll need:

- PowerShell 7.0 or higher (recommended)
- Azure PowerShell modules
- Git
- An Azure subscription for testing
- Visual Studio Code or another editor

### Setting Up Your Development Environment

#### Option 1: Using DevContainers (Recommended)

The fastest way to get started is using DevContainers, which provides a consistent development environment with all dependencies pre-installed:

1. Fork the repository on GitHub
2. Clone your fork to your local machine:
   ```
   git clone https://github.com/your-username/ARI.git
   ```
3. Open the project in Visual Studio Code
4. When prompted, click "Reopen in Container" or press `Ctrl+Shift+P` and select "Dev Containers: Reopen in Container"
5. Wait for the container to build (first time only, ~5-10 minutes)
6. The environment will automatically validate and be ready for development

The DevContainer includes:
- PowerShell 7.4
- All required PowerShell modules (Az.*, ImportExcel, etc.)
- Azure CLI
- Git and development tools
- VS Code extensions for PowerShell and Azure development

#### Option 2: Local Development Setup

If you prefer to set up your local environment manually:

1. Fork the repository on GitHub
2. Clone your fork to your local machine:
   ```
   git clone https://github.com/your-username/ARI.git
   ```
3. Add the upstream repository as a remote:
   ```
   git remote add upstream https://github.com/microsoft/ARI.git
   ```
4. Install required PowerShell modules:
   ```powershell
   Install-Module -Name ImportExcel, Az.Accounts, Az.ResourceGraph, Az.Storage, Az.Compute, Az.CostManagement -Force
   ```
5. Create a new branch for your changes:
   ```
   git checkout -b my-feature-branch
   ```

#### Validating Your Environment

Regardless of which setup method you choose, you can validate your environment by running:

```powershell
./scripts/validate-environment.ps1
```

This script will check that all required components are properly installed and configured.

## Development Guidelines

### Code Style

- Follow PowerShell best practices
- Use clear, descriptive variable and function names
- Add appropriate comments for complex logic
- Follow the existing code structure and patterns

### Adding Features

1. If adding a new resource type:
   - Create a new module in the appropriate directory under `Modules/Public/InventoryModules/`
   - Follow the existing resource type module patterns
   - Update the resource types documentation

2. If enhancing existing functionality:
   - Maintain backward compatibility when possible
   - Test thoroughly on different Azure environments

### Testing Your Changes

Before submitting a pull request:

1. Test your changes with different Azure environments if possible
2. Ensure no regressions in existing functionality
3. Verify the module loads without errors
4. Test any new parameters or functions

### Documentation

When contributing new features or changes:

1. Update or add documentation for new functionality
2. Include examples of how to use new features
3. Update the parameter reference if adding parameters

## Pull Request Process

1. Ensure your code follows the style guidelines
2. Update documentation as necessary
3. Squash commits into logical units
4. Submit a pull request to the `main` branch
5. In the pull request description, explain the changes and the motivation behind them

### Pull Request Checklist

- [ ] Code follows style guidelines
- [ ] Tests added/updated for new functionality
- [ ] Documentation updated
- [ ] Changes maintain backward compatibility (or explain breaking changes)
- [ ] Squashed commits with clear messages

## Issue Reporting

If you find a bug or have a feature request:

1. Check if the issue already exists in the [GitHub issue tracker](https://github.com/microsoft/ARI/issues)
2. If not, create a new issue with a clear description
3. For bugs, include:
   - Steps to reproduce
   - Expected behavior
   - Actual behavior
   - PowerShell and module versions
   - Any error messages

## Getting Help

If you need help with your contribution:

- Ask questions in the issue for your pull request
- Reach out to the maintainers
- Check the [README](https://github.com/microsoft/ARI/blob/main/README.md) for additional information

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/).

## Thank You

Your contributions to Azure Resource Inventory help improve the tool for everyone. We appreciate your time and effort! 