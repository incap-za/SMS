#======================================================================
# Author:      KPN Integration Team
# Date:        ${date}
# Description: Deploy SMS workflow to shared Logic App in ASE
#======================================================================

param(
    [ValidateSet("dev","acc","prd")]
    [Parameter(Mandatory=$true)]
    $Environment,
    [Parameter(Mandatory=$false)]
    $BranchName
)
cls
# get git directory path
$GitDirectory = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName
 
# if local, check connection and connect if needed; for devops, connect with identity
if ($GitDirectory -eq "C:\src\repositories\kai-main") {
    $TestAccountInfo = Get-AzContext | select-object Account
    $AzSubscription = Get-AzSubscription
    if (([string]::IsNullOrEmpty($TestAccountInfo)) -and  ($TestAccountInfo  -notcontains "@kpn.com") -or ([string]::IsNullOrEmpty($AzSubscription)))  {Connect-AzAccount}
} else {
    Connect-AzAccount -Identity
}
# Stop on Error
$ErrorActionPreference = "Stop"

if($BranchName){
    # Pipeline deployment should forward branch name
    Write-Host("BRANCH: $BranchName")    
} else {
    # For local deployment, get branchname
    $BranchName = git rev-parse --abbrev-ref HEAD
    Write-Host("BRANCH: '$BranchName'")
}

# Set subscription based on environment - REPLACE WITH ACTUAL IDs
$SubscriptionId = switch ($Environment) {
    "dev" { "REPLACE-WITH-DEV-SUBSCRIPTION-ID" }
    "acc" { "REPLACE-WITH-ACC-SUBSCRIPTION-ID" }
    "prd" { "REPLACE-WITH-PRD-SUBSCRIPTION-ID" }
}

Set-AzContext -SubscriptionId $SubscriptionId

# Variables
$ResourceGroupName = "$Environment-as-is-rg"
$SharedLogicAppName = "dev-api-ticket-la"  # Using the correct Logic App name
$WorkflowName = "sms-post-kpnsms-wf"
$WorkflowFilePath = "$GitDirectory\LogicApps\dev-api-ticket-la\workflows\$WorkflowName.json"

Write-Host "Deploying SMS workflow to shared Logic App..." -ForegroundColor Green
Write-Host "Environment: $Environment"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Logic App: $SharedLogicAppName"
Write-Host "Workflow: $WorkflowName"

# Check if Logic App (Standard) exists
$LogicApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $SharedLogicAppName -ErrorAction SilentlyContinue
if ($null -eq $LogicApp) {
    Write-Error "Logic App '$SharedLogicAppName' not found in resource group '$ResourceGroupName'"
    exit 1
}

# Read workflow definition
if (Test-Path $WorkflowFilePath) {
    $WorkflowDefinition = Get-Content $WorkflowFilePath -Raw | ConvertFrom-Json
} else {
    Write-Error "Workflow file not found at: $WorkflowFilePath"
    exit 1
}

# Deploy workflow to Logic App Standard
try {
    # Get access token
    $token = (Get-AzAccessToken -ResourceUrl "https://management.azure.com/").Token
    $headers = @{
        'Authorization' = "Bearer $token"
        'Content-Type' = 'application/json'
    }
    
    # Construct the correct URI for Logic App Standard workflow
    $apiVersion = "2022-03-01"
    $baseUri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$SharedLogicAppName"
    
    # First, ensure the workflow folder exists
    $workflowFolderUri = "$baseUri/hostruntime/runtime/webhooks/workflow/api/management/workflows/$WorkflowName`?api-version=$apiVersion"
    
    # Create workflow body
    $workflowBody = @{
        "id" = $WorkflowName
        "name" = $WorkflowName
        "type" = "Microsoft.Logic/workflows"
        "kind" = $WorkflowDefinition.kind
        "properties" = @{
            "flowState" = if ($WorkflowDefinition.properties.state) { $WorkflowDefinition.properties.state } else { "Enabled" }
            "definition" = $WorkflowDefinition.definition
            "parameters" = if ($WorkflowDefinition.properties.parameters) { $WorkflowDefinition.properties.parameters } else { @{} }
        }
    } | ConvertTo-Json -Depth 100
    
    # Deploy the workflow
    $response = Invoke-RestMethod -Uri $workflowFolderUri -Method Put -Headers $headers -Body $workflowBody
    
    Write-Host "Workflow '$WorkflowName' deployed successfully!" -ForegroundColor Green
    
} catch {
    Write-Error "Failed to deploy workflow: $_"
    Write-Error "Response: $($_.Exception.Response.Content.ReadAsStringAsync().Result)"
    exit 1
}

# Update App Settings for the shared Logic App
Write-Host "Updating App Settings..." -ForegroundColor Yellow

# Environment-specific KPN SMS API settings
$KpnSmsClientId = switch ($Environment) {
    "dev" { "sms-api-dev-client-id" }  # Replace with actual client IDs
    "acc" { "sms-api-acc-client-id" }
    "prd" { "sms-api-prd-client-id" }
}

$AppSettings = @{
    "KpnSmsClientId" = $KpnSmsClientId
    "KpnSmsClientSecret" = "@Microsoft.KeyVault(SecretUri=https://$Environment-kv.vault.azure.net/secrets/kpn-sms-client-secret/)"
    "KeyVaultUrl" = "https://$Environment-kv.vault.azure.net"
    "SmsWebhookUrl" = "" # Set if webhook notifications are needed
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = "@Microsoft.KeyVault(SecretUri=https://$Environment-kv.vault.azure.net/secrets/storage-connection-string/)"
    "WEBSITE_CONTENTSHARE" = $SharedLogicAppName
    "AzureWebJobsStorage" = "@Microsoft.KeyVault(SecretUri=https://$Environment-kv.vault.azure.net/secrets/storage-connection-string/)"
}

# Get existing app settings
$webapp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $SharedLogicAppName
$existingAppSettings = $webapp.SiteConfig.AppSettings

# Convert to hashtable
$appSettingsHashtable = @{}
foreach ($setting in $existingAppSettings) {
    $appSettingsHashtable[$setting.Name] = $setting.Value
}

# Add/update new settings
foreach ($key in $AppSettings.Keys) {
    $appSettingsHashtable[$key] = $AppSettings[$key]
}

# Update app settings
Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $SharedLogicAppName -AppSettings $appSettingsHashtable

Write-Host "App Settings updated successfully!" -ForegroundColor Green

# Create or update connections.json if needed
Write-Host "Checking workflow connections..." -ForegroundColor Yellow

$connectionsPath = "$GitDirectory\LogicApps\dev-api-ticket-la\connections.json"
if (Test-Path $connectionsPath) {
    Write-Host "Connections.json found, no update needed." -ForegroundColor Green
} else {
    Write-Host "Creating connections.json..." -ForegroundColor Yellow
    $connections = @{
        "managedApiConnections" = @{}
        "serviceProviderConnections" = @{}
    } | ConvertTo-Json -Depth 10
    
    New-Item -Path $connectionsPath -ItemType File -Value $connections -Force
    Write-Host "Connections.json created." -ForegroundColor Green
}

# Deploy API Management update
CD "$GitDirectory\Deployment\APIManagement"
Write-Host "Updating API Management configuration..." -ForegroundColor Yellow
.\DeployApi -Environment $Environment -SwaggerFileName "sms-kpn-rest-api.json"

Write-Host "Deployment completed successfully!" -ForegroundColor Green
