# System Patterns: Azure Resource Inventory (ARI)

## System Architecture

### Overall Architecture
Azure Resource Inventory (ARI) follows a modular architecture that enables flexibility, extensibility, and cross-platform compatibility. The system is structured as a PowerShell module with the following key components:

1. **Core Engine**: Handles authentication, resource discovery, and orchestration
2. **Resource Collectors**: Specialized modules for each resource type
3. **Data Processors**: Transform raw Azure data into structured formats
4. **Report Generators**: Create Excel reports and diagrams
5. **API Integrators**: Connect to additional data sources via REST APIs

### Component Relationships
```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│  Authentication ├────►│ Resource        ├────►│ Data            │
│  & Context      │     │ Collection      │     │ Processing      │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│  Report         │◄────┤ Data            │◄────┤ Advisory &      │
│  Generation     │     │ Visualization   │     │ Security Data   │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## Key Technical Decisions

### PowerShell Module Format
ARI is implemented as a standard PowerShell module, which provides:
- Easy installation via PowerShell Gallery
- Standardized command structure
- Simplified updates and versioning
- Cross-platform compatibility

### Data Collection Strategy
- **Read-Only Operations**: All data collection is performed using read-only API calls to ensure no changes are made to the environment
- **Parallel Processing**: Where possible, data collection is parallelized to improve performance
- **Pagination Handling**: APIs that return large datasets are handled with proper pagination
- **Error Resilience**: Collection continues even if individual resource queries fail

### Report Generation Approach
- **Excel as Output Format**: Excel provides rich formatting and filtering capabilities
- **Workbook Structure**: Each resource type gets its own worksheet
- **Conditional Formatting**: Visual indicators highlight important information
- **Data Validation**: Ensures consistency and accuracy in the reports

### Diagram Generation
- **Draw.IO Format**: Industry-standard diagram format with wide compatibility
- **Automated Layout**: Intelligent positioning of resources based on relationships
- **Interactive Elements**: Clickable elements for navigation within complex diagrams

## Design Patterns

### Module Pattern
ARI uses the PowerShell module pattern to encapsulate functionality and provide a clean interface for users.

### Factory Pattern
Resource collectors are implemented using a factory pattern, allowing new resource types to be added without modifying the core engine.

### Strategy Pattern
Different reporting strategies (full, lite, etc.) are implemented using the strategy pattern, allowing users to choose the appropriate output format.

### Observer Pattern
The progress reporting system uses an observer pattern to provide real-time updates during long-running operations.

### Adapter Pattern
The REST API integration uses adapters to normalize data from different sources into a consistent format.

## Technical Standards

### Code Organization
- **Modules Directory**: Contains resource-specific collection modules
- **Root Scripts**: Main entry points and orchestration
- **Automation Directory**: Contains Automation Account integration resources

### Naming Conventions
- **Functions**: Verb-Noun format (e.g., `Get-AzureInventoryResource`)
- **Variables**: Descriptive camelCase names
- **Parameters**: PascalCase with clear descriptions
- **Files**: Descriptive names indicating purpose

### Error Handling
- **Try-Catch Blocks**: Used for recoverable errors
- **Verbose Logging**: Detailed error information for troubleshooting
- **Graceful Degradation**: Continue operation when possible, even if some components fail

### Performance Considerations
- **Batch Processing**: Group API calls where possible
- **Resource Throttling**: Respect Azure API limits
- **Memory Management**: Process large datasets in chunks
- **Progress Reporting**: Keep users informed during long-running operations

## Created
Date: 2025-03-21
Time: 13:49:00 +10:00
