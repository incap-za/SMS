#======================================================================
# Author:      ctp
# Date:        auto generated
# Description: TEMPLATE FOR POWERSHELL DEPLOYMENT
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


CD "$GitDirectory\Deployment\LogicApps"
# Deploy LogicApp & Workflow artifacts
.\DeployLA -Environment $Environment -LogicAppFolder "rest-ib-sms-la" -BranchName $BranchName
.\DeployWF -Environment $Environment -LogicAppFolder "rest-ib-sms-la" -BranchName $BranchName

# Deploy AppSettings artifacts
.\DeployAppSettings -Environment $Environment -LogicAppFolder "rest-ib-sms-la" -BranchName $BranchName

CD "$GitDirectory\Deployment\APIManagement"
.\DeployApi -Environment $Environment -SwaggerFileName "sms-kpn-rest-api.json"