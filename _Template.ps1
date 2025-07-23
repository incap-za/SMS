#======================================================================
# Author:      ctp
# Date:        2023 September 6
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
    # Only relevant in case of ADF deployment
    #if ($Environment -eq "dev") { Select-AzSubscription -SubscriptionName 'KPN B2B Integrations DEV'}
    #if ($Environment -eq "acc") { Select-AzSubscription -SubscriptionName 'KPN B2B Integrations ACC'}
    #if ($Environment -eq "prd") { Select-AzSubscription -SubscriptionName 'KPN B2B Integrations PROD'}
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
    # SQL QUERY
    .\Deploy-SQL -Environment $Environment -SqlQuery "HERE THE SQL QUERY"
    # SQL SCRIPT
    # To KAI-DB
    .\Deploy-SQL -Environment $Environment -SqlScriptPath "$GitDirectory\DeploymentScripts\2025\FOLDER\SCRIPT.sql"
    .\Deploy-SQL -Environment $Environment -SqlScriptPath "$gitDirectory\Projects\SQL\kai-db\stored-procedures\p_x.sql"
    .\Deploy-SQL -Environment $Environment -SqlScriptPath "$gitDirectory\Projects\SQL\Config\CUSTOMER\CONFIGTABLE.sql"
    # To SNDATAHUB-GREEN
    .\Deploy-SQL -Environment $Environment -Database "Datahub-Green" -SqlScriptPath "$gitDirectory\Projects\SQL\sn-datahub-db\stored-procedures\p_x.sql"
    # To SNDATAHUB-RED
    .\Deploy-SQL -Environment $Environment -Database "Datahub-Red" -SqlScriptPath "$gitDirectory\Projects\SQL\snred-datahub-db\stored-procedures\p_x.sql"
}

CD "$GitDirectory\Deployment\LogicApps"
# Deploy LogicApp & Workflow artifacts
.\DeployLA -Environment $Environment -LogicAppFolder "sample-la" -BranchName $BranchName
.\DeployWF -Environment $Environment -LogicAppFolder "sample-la" -BranchName $BranchName

# Deploy AppSettings artifacts
.\DeployAppSettings -Environment $Environment -LogicAppFolder "sample-la" -BranchName $BranchName

# Deploy api 
CD "$GitDirectory\Deployment\APIManagement"
.\DeployApi -Environment $Environment -SwaggerFileName "kpn-sn-ticket-ob-api.json"