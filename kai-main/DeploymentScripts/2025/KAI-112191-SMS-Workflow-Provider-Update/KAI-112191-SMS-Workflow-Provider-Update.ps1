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

# Deploy SQL, only via pipeline
CD "$GitDirectory\Deployment\SQLDeployment"
if($GitDirectory -ne "C:\src\repositories\kai-main"){
    # SQL SCRIPT
    # To KAI-DB
    .\Deploy-SQL -Environment $Environment -SqlScriptPath "$GitDirectory\DeploymentScripts\2025\KAI-112191-SMS-Workflow-Provider-Update\sms-token-config.sql"
}

CD "$GitDirectory\Deployment\LogicApps"
# Deploy Workflow
.\DeployWF -Environment $Environment -LogicAppFolder "$Environment-api-ticket-la" -BranchName $BranchName
