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

# Set subscription based on environment
$SubscriptionId = switch ($Environment) {
    "dev" { "your-dev-subscription-id" }
    "acc" { "your-acc-subscription-id" }
    "prd" { "your-prd-subscription-id" }
}

Set-AzContext -SubscriptionId $SubscriptionId

# Variables
$ResourceGroupName = "$Environment-as-is-rg"
$SharedLogicAppName = "dev-api-ticket-la"
$WorkflowName = "sms-post-kpnsms-wf"
$WorkflowFilePath = "$GitDirectory\LogicApps\dev-api-ticket-la\workflows\$WorkflowName.json"

Write-Host "Deploying SMS workflow to shared Logic App..." -ForegroundColor Green
Write-Host "Environment: $Environment"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Logic App: $SharedLogicAppName"
Write-Host "Workflow: $WorkflowName"

# Check if Logic App exists
$LogicApp = Get-AzLogicApp -ResourceGroupName $ResourceGroupName -Name $SharedLogicAppName -ErrorAction SilentlyContinue
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

# Deploy workflow to shared Logic App
try {
    # Create or update workflow
    $apiVersion = "2019-05-01"
    $resourceId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Logic/workflows/$SharedLogicAppName/versions/$WorkflowName"
    
    # Use Azure REST API to deploy workflow
    $token = (Get-AzAccessToken).Token
    $headers = @{
        'Authorization' = "Bearer $token"
        'Content-Type' = 'application/json'
    }
    
    $uri = "https://management.azure.com$resourceId`?api-version=$apiVersion"
    
    $body = @{
        properties = @{
            definition = $WorkflowDefinition.definition
            parameters = @{}
            state = "Enabled"
        }
        kind = $WorkflowDefinition.kind
    } | ConvertTo-Json -Depth 100
    
    $response = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $body
    
    Write-Host "Workflow '$WorkflowName' deployed successfully!" -ForegroundColor Green
} catch {
    Write-Error "Failed to deploy workflow: $_"
    exit 1
}

# Update App Settings for the shared Logic App
Write-Host "Updating App Settings..." -ForegroundColor Yellow

$AppSettings = @{
    "KpnSmsClientId" = "@Microsoft.KeyVault(SecretUri=https://$Environment-kv.vault.azure.net/secrets/kpn-sms-client-id/)"
    "KpnSmsClientSecret" = "@Microsoft.KeyVault(SecretUri=https://$Environment-kv.vault.azure.net/secrets/kpn-sms-client-secret/)"
    "KeyVaultUrl" = "https://$Environment-kv.vault.azure.net"
    "SmsWebhookUrl" = "" # Set if webhook notifications are needed
}

# Get existing app settings
$webapp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $SharedLogicAppName
$existingAppSettings = $webapp.SiteConfig.AppSettings

# Convert to hashtable
$appSettingsHashtable = @{}
foreach ($setting in $existingAppSettings) {
    $appSettingsHashtable[$setting.Name] = $setting.Value
}

# Add new settings
foreach ($key in $AppSettings.Keys) {
    $appSettingsHashtable[$key] = $AppSettings[$key]
}

# Update app settings
Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $SharedLogicAppName -AppSettings $appSettingsHashtable

Write-Host "App Settings updated successfully!" -ForegroundColor Green

# Deploy API Management update if needed
CD "$GitDirectory\Deployment\APIManagement"
Write-Host "Updating API Management configuration..." -ForegroundColor Yellow
.\DeployApi -Environment $Environment -SwaggerFileName "sms-kpn-rest-api.json"

Write-Host "Deployment completed successfully!" -ForegroundColor Green