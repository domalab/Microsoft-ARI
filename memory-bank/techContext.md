# Technical Context: Azure Resource Inventory (ARI)

## Technologies Used

### Core Technologies
- **PowerShell**: Primary scripting language (7.0+ recommended, 5.1 supported)
- **Azure PowerShell Modules**: For Azure resource management and data collection
- **Azure REST APIs**: For additional data sources not available through PowerShell modules
- **Excel**: Output format for comprehensive reports

### PowerShell Modules
- **Az Module**: Core Azure PowerShell module for resource management
- **ImportExcel**: For Excel report generation without requiring Excel installation
- **PSGraph**: For diagram generation capabilities

### Azure Services Integrated
- **Azure Resource Manager**: Primary interface for resource discovery
- **Azure Security Center**: Optional integration for security insights
- **Azure Advisor**: For optimization recommendations
- **Azure Support**: For ticket information
- **Azure Health**: For service health incidents

## Development Setup

### Local Development Environment
- **PowerShell 7.0+**: Recommended for full functionality
- **Az PowerShell Module**: Required for Azure resource access
- **Git**: For version control
- **Visual Studio Code**: Recommended editor with PowerShell extension

### Required Permissions
- **Read Access**: Minimum permission level for Azure resources
- **Security Reader**: Required for Security Center integration
- **Support Request Contributor**: Required for support ticket information

### Installation Methods
1. **PowerShell Gallery**:
   ```powershell
   Install-Module -Name AzureResourceInventory
   ```

2. **Manual Installation**:
   ```powershell
   # Clone repository
   git clone https://github.com/microsoft/ARI.git
   
   # Navigate to directory
   cd ARI
   
   # Run locally
   .\Run-LocalARI.ps1
   ```

3. **Automation Account**:
   - Import module to Automation Account
   - Configure runbook with appropriate parameters
   - Schedule execution as needed

## Technical Constraints

### Azure Limitations
- **API Rate Limits**: Large environments may encounter throttling
- **Resource Type Support**: New Azure resource types may not be immediately supported
- **Regional Availability**: Some features depend on regional availability of Azure services

### Performance Considerations
- **Large Environments**: Processing time increases with environment size
- **Memory Usage**: Excel generation requires sufficient memory
- **Network Bandwidth**: Data collection depends on network performance

### Cross-Platform Compatibility
- **Windows**: Full support for all features
- **Linux/Mac**: Full support via PowerShell 7.0+
- **Azure Cloud Shell**: Supported with some limitations (browser download for reports)

## Dependencies

### Required Dependencies
- **PowerShell 7.0+** (recommended) or **PowerShell 5.1**
- **Az PowerShell Module** (minimum version: 5.0.0)
- **ImportExcel Module** (minimum version: 7.1.0)

### Optional Dependencies
- **PSGraph Module**: For diagram generation
- **Azure CLI**: Alternative authentication method

### External Services
- **Azure Resource Manager API**: Primary data source
- **Azure REST APIs**: Additional data sources
- **Microsoft Graph API**: For certain tenant information

## Version Compatibility

### PowerShell Compatibility
- **PowerShell 7.x**: Full support, recommended
- **PowerShell 5.1**: Supported with some limitations
- **PowerShell Core 6.x**: Supported but not actively tested

### Az Module Compatibility
- **Az 5.0.0+**: Full support
- **Az 4.x**: Basic functionality, some features may not work
- **AzureRM**: Not supported (legacy module)

### Operating System Compatibility
- **Windows 10/11**: Full support
- **Windows Server 2016+**: Full support
- **Ubuntu 18.04+**: Supported via PowerShell 7
- **macOS 10.15+**: Supported via PowerShell 7

## Created
Date: 2025-03-21
Time: 13:50:00 +10:00
