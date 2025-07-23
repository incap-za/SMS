#======================================================================
# Author:      KPN Integration Team
# Date:        2025-01-23
# Description: Deploy SMS API migration from Vonage to KPN SMS provider
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

# Deploy SQL Token Configuration, only via pipeline
CD "$GitDirectory\Deployment\SQLDeployment"
if($GitDirectory -ne "C:\src\repositories\kai-main"){
    Write-Host "Deploying SMS Token Configuration to KAI-DB..." -ForegroundColor Green
    .\Deploy-SQL -Environment $Environment -SqlScriptPath "$GitDirectory\DeploymentScripts\2025\SMS-Migration\update-sms-token-config.sql"
}

CD "$GitDirectory\Deployment\LogicApps"
# Deploy workflow to existing shared Logic App
$SharedLogicAppName = "$Environment-api-ticket-la"
Write-Host "Deploying SMS workflow 'sms-post-kpnsms-wf' to shared Logic App '$SharedLogicAppName'..." -ForegroundColor Green

# Deploy the workflow to the existing Logic App
.\DeployWF -Environment $Environment -LogicAppFolder $SharedLogicAppName -BranchName $BranchName

# Note: No need to deploy the Logic App itself or App Settings as it already exists
# The shared Logic App should already have the necessary settings for token service

# Deploy SMS API to API Management (if needed)
CD "$GitDirectory\Deployment\APIManagement"
Write-Host "Checking SMS API in API Management..." -ForegroundColor Yellow

# Check if we need to update the API or if it's already pointing to the correct endpoint
# The API name 'sms-kpn-rest-api' might already exist pointing to the current Vonage implementation
# In DEV, we might want to create a new version or update the existing one

if ($Environment -eq "dev") {
    Write-Host "In DEV environment - API Management update will be handled separately" -ForegroundColor Yellow
    Write-Host "The existing SMS API in APIM still points to the current implementation" -ForegroundColor Yellow
    Write-Host "Once testing is complete, update the APIM backend to point to the new workflow" -ForegroundColor Yellow
} else {
    # For ACC/PRD deployment after DEV testing is complete
    Write-Host "Updating SMS API in API Management..." -ForegroundColor Green
    .\DeployApi -Environment $Environment -SwaggerFileName "sms-kpn-rest-api.json"
}

Write-Host "SMS API Migration deployment completed successfully!" -ForegroundColor Green
Write-Host "Workflow 'sms-post-kpnsms-wf' deployed to Logic App '$SharedLogicAppName'" -ForegroundColor Green

if ($Environment -eq "dev") {
    Write-Host "" -ForegroundColor Yellow
    Write-Host "IMPORTANT: Next steps for DEV testing:" -ForegroundColor Yellow
    Write-Host "1. The new workflow is deployed but not yet connected to APIM" -ForegroundColor Yellow
    Write-Host "2. Test the workflow directly using the Logic App endpoint" -ForegroundColor Yellow
    Write-Host "3. Once testing is successful, update APIM to point to the new workflow" -ForegroundColor Yellow
    Write-Host "4. Both Vonage and KPN SMS implementations are currently active" -ForegroundColor Yellow
}
