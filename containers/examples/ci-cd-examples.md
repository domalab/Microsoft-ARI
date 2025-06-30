# CI/CD Integration Examples

This guide shows how to integrate ARI containers into various CI/CD platforms to automate Azure inventory reporting.

## GitHub Actions

### Basic Workflow
```yaml
# .github/workflows/azure-inventory.yml
name: Azure Resource Inventory

on:
  schedule:
    # Run every Monday at 8 AM UTC
    - cron: '0 8 * * 1'
  workflow_dispatch:
    inputs:
      tenant_id:
        description: 'Azure Tenant ID'
        required: true
        type: string
      subscription_id:
        description: 'Azure Subscription ID (optional)'
        required: false
        type: string

jobs:
  generate-inventory:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Build ARI container
      run: |
        docker build -t ari:latest containers/runtime/
        
    - name: Generate Azure inventory
      env:
        AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
        AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
        AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
        ARI_TENANT_ID: ${{ github.event.inputs.tenant_id || secrets.DEFAULT_TENANT_ID }}
        ARI_SUBSCRIPTION_ID: ${{ github.event.inputs.subscription_id }}
      run: |
        mkdir -p ./reports
        docker run --rm \
          -v $(pwd)/reports:/ari-output \
          -e AZURE_CLIENT_ID \
          -e AZURE_CLIENT_SECRET \
          -e AZURE_TENANT_ID \
          ari:latest \
          pwsh -c "Import-Module /opt/ari/AzureResourceInventory.psm1; Invoke-ARI -TenantID '$ARI_TENANT_ID' $(if [ -n '$ARI_SUBSCRIPTION_ID' ]; then echo '-SubscriptionID $ARI_SUBSCRIPTION_ID'; fi) -ReportName 'ARI-$(date +%Y%m%d)'"
          
    - name: Upload inventory reports
      uses: actions/upload-artifact@v4
      with:
        name: azure-inventory-reports
        path: ./reports/*.xlsx
        retention-days: 30
        
    - name: Upload to Azure Storage (optional)
      if: success()
      env:
        AZURE_STORAGE_ACCOUNT: ${{ secrets.AZURE_STORAGE_ACCOUNT }}
        AZURE_STORAGE_KEY: ${{ secrets.AZURE_STORAGE_KEY }}
      run: |
        az storage blob upload-batch \
          --destination reports \
          --source ./reports \
          --account-name $AZURE_STORAGE_ACCOUNT \
          --account-key $AZURE_STORAGE_KEY
```

### Multi-tenant Workflow
```yaml
# .github/workflows/multi-tenant-inventory.yml
name: Multi-tenant Azure Inventory

on:
  schedule:
    - cron: '0 6 * * 1'  # Weekly on Monday at 6 AM
  workflow_dispatch:

jobs:
  multi-tenant-inventory:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
      
    - name: Build ARI container
      run: docker build -t ari:latest containers/runtime/
      
    - name: Generate multi-tenant inventory
      env:
        AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
        AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
        AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      run: |
        cd containers/
        cp .env.example .env
        echo "ARI_TENANTS_CONFIG=./examples/tenants.json" >> .env
        docker-compose --profile multitenant up ari-multitenant
        
    - name: Archive all reports
      uses: actions/upload-artifact@v4
      with:
        name: multi-tenant-reports-${{ github.run_number }}
        path: containers/output/*.xlsx
```

## Azure DevOps

### Pipeline YAML
```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main
  schedules:
  - cron: "0 8 * * Mon"
    displayName: Weekly inventory
    branches:
      include:
      - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: azure-credentials  # Variable group with service principal details

stages:
- stage: BuildContainer
  displayName: 'Build ARI Container'
  jobs:
  - job: Build
    steps:
    - task: Docker@2
      displayName: 'Build ARI image'
      inputs:
        command: 'build'
        Dockerfile: 'containers/runtime/Dockerfile'
        tags: 'ari:$(Build.BuildNumber)'
        
- stage: GenerateInventory
  displayName: 'Generate Azure Inventory'
  dependsOn: BuildContainer
  jobs:
  - job: RunInventory
    steps:
    - script: |
        mkdir -p $(Pipeline.Workspace)/reports
        docker run --rm \
          -v $(Pipeline.Workspace)/reports:/ari-output \
          -e AZURE_CLIENT_ID="$(AZURE_CLIENT_ID)" \
          -e AZURE_CLIENT_SECRET="$(AZURE_CLIENT_SECRET)" \
          -e AZURE_TENANT_ID="$(AZURE_TENANT_ID)" \
          ari:$(Build.BuildNumber) \
          pwsh -c "Import-Module /opt/ari/AzureResourceInventory.psm1; Invoke-ARI -TenantID '$(ARI_TENANT_ID)' -ReportName 'ARI-$(Build.BuildNumber)' -IncludeTags"
      displayName: 'Run ARI container'
      
    - task: PublishBuildArtifacts@1
      inputs:
        PathtoPublish: '$(Pipeline.Workspace)/reports'
        ArtifactName: 'azure-inventory'
        publishLocation: 'Container'
```

## Jenkins

### Jenkinsfile
```groovy
pipeline {
    agent any
    
    parameters {
        string(name: 'TENANT_ID', description: 'Azure Tenant ID')
        string(name: 'SUBSCRIPTION_ID', description: 'Azure Subscription ID (optional)', defaultValue: '')
        booleanParam(name: 'INCLUDE_TAGS', description: 'Include resource tags', defaultValue: true)
        booleanParam(name: 'SECURITY_CENTER', description: 'Include Security Center data', defaultValue: false)
    }
    
    environment {
        AZURE_CLIENT_ID = credentials('azure-client-id')
        AZURE_CLIENT_SECRET = credentials('azure-client-secret')
        AZURE_TENANT_ID = credentials('azure-tenant-id')
    }
    
    stages {
        stage('Build Container') {
            steps {
                script {
                    def ariImage = docker.build("ari:${env.BUILD_NUMBER}", "containers/runtime/")
                }
            }
        }
        
        stage('Generate Inventory') {
            steps {
                script {
                    sh "mkdir -p ${WORKSPACE}/reports"
                    
                    def ariParams = "-TenantID '${params.TENANT_ID}'"
                    if (params.SUBSCRIPTION_ID) {
                        ariParams += " -SubscriptionID '${params.SUBSCRIPTION_ID}'"
                    }
                    if (params.INCLUDE_TAGS) {
                        ariParams += " -IncludeTags"
                    }
                    if (params.SECURITY_CENTER) {
                        ariParams += " -SecurityCenter"
                    }
                    ariParams += " -ReportName 'ARI-${env.BUILD_NUMBER}'"
                    
                    sh """
                        docker run --rm \
                          -v ${WORKSPACE}/reports:/ari-output \
                          -e AZURE_CLIENT_ID \
                          -e AZURE_CLIENT_SECRET \
                          -e AZURE_TENANT_ID \
                          ari:${env.BUILD_NUMBER} \
                          pwsh -c "Import-Module /opt/ari/AzureResourceInventory.psm1; Invoke-ARI ${ariParams}"
                    """
                }
            }
        }
        
        stage('Archive Reports') {
            steps {
                archiveArtifacts artifacts: 'reports/*.xlsx', fingerprint: true
                
                // Optional: Upload to network share or cloud storage
                script {
                    if (env.REPORTS_SHARE_PATH) {
                        sh "cp reports/*.xlsx ${env.REPORTS_SHARE_PATH}/"
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            emailext (
                subject: "Azure Inventory Report Generated - Build ${env.BUILD_NUMBER}",
                body: "The Azure inventory report has been successfully generated. Check the build artifacts for the Excel files.",
                to: "${env.NOTIFICATION_EMAIL}"
            )
        }
        failure {
            emailext (
                subject: "Azure Inventory Report Failed - Build ${env.BUILD_NUMBER}",
                body: "The Azure inventory report generation failed. Check the build logs for details.",
                to: "${env.NOTIFICATION_EMAIL}"
            )
        }
    }
}
```

## GitLab CI

### .gitlab-ci.yml
```yaml
stages:
  - build
  - inventory
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  ARI_IMAGE: "ari:$CI_PIPELINE_ID"

build-container:
  stage: build
  script:
    - docker build -t $ARI_IMAGE containers/runtime/
  only:
    - schedules
    - web

generate-inventory:
  stage: inventory
  script:
    - mkdir -p reports
    - |
      docker run --rm \
        -v $(pwd)/reports:/ari-output \
        -e AZURE_CLIENT_ID="$AZURE_CLIENT_ID" \
        -e AZURE_CLIENT_SECRET="$AZURE_CLIENT_SECRET" \
        -e AZURE_TENANT_ID="$AZURE_TENANT_ID" \
        $ARI_IMAGE \
        pwsh -c "Import-Module /opt/ari/AzureResourceInventory.psm1; Invoke-ARI -TenantID '$ARI_TENANT_ID' -ReportName 'ARI-$CI_PIPELINE_ID' -IncludeTags"
  artifacts:
    name: "azure-inventory-$CI_PIPELINE_ID"
    paths:
      - reports/*.xlsx
    expire_in: 1 month
  dependencies:
    - build-container

upload-to-storage:
  stage: deploy
  script:
    - az storage blob upload-batch --destination reports --source ./reports --account-name $STORAGE_ACCOUNT --account-key $STORAGE_KEY
  dependencies:
    - generate-inventory
  only:
    - schedules
```

## Scheduled Execution with Cron

### Linux/Mac Cron Job
```bash
# Add to crontab (crontab -e)
# Run every Monday at 8 AM
0 8 * * 1 /path/to/ari-project/containers/scripts/run-ari.sh --tenant-id "your-tenant-id" --report-name "Weekly-$(date +\%Y\%m\%d)" >> /var/log/ari-cron.log 2>&1
```

### Windows Task Scheduler PowerShell
```powershell
# Create scheduled task
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\ARI\containers\scripts\run-ari.ps1 -TenantId 'your-tenant-id' -ReportName 'Weekly-$(Get-Date -Format yyyyMMdd)'"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 8AM
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "ARI Weekly Report" -Action $action -Trigger $trigger -Settings $settings
```

## Best Practices for CI/CD

1. **Use Service Principal Authentication**
   - Create dedicated service principals for automation
   - Store credentials securely in CI/CD secret management
   - Rotate credentials regularly

2. **Parameterize Configurations**
   - Use environment-specific configurations
   - Allow manual override of tenant/subscription IDs
   - Configure different report names per environment

3. **Handle Artifacts Properly**
   - Archive reports with meaningful names
   - Set appropriate retention periods
   - Consider uploading to centralized storage

4. **Monitor and Alert**
   - Set up notifications for failed runs
   - Monitor execution time and resource usage
   - Log execution details for troubleshooting

5. **Security Considerations**
   - Use least-privilege service principals
   - Scan container images for vulnerabilities
   - Audit access to generated reports