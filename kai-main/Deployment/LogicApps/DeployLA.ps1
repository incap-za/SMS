#======================================================================
# Author:       CTP &TDN
# Date:         2024 January 18
# Description:  Creation of Standard Logic App with necessary infra
#
# Parameters:
#   - Environment:      The environment where to install
#   - LogicAppFolder:   The foldername of the logic app in the repo
#======================================================================

param(
    [ValidateSet("dev","acc","prd")]
    [Parameter(Mandatory=$true)]
    $Environment,
    [Parameter(Mandatory=$true)]
    $LogicAppFolder,
    [Parameter(Mandatory=$true)]
    $BranchName
)
# stop execution as encounter any exception
$ErrorActionPreference = "Stop"
Write-Host("######################################################################################")
$startDate =(Get-Date)
# setting global variables
$Global:BASEPATH = $PSScriptRoot.Replace("Deployment","Projects")
Write-Host("BASEPATH: '$Global:BASEPATH'")
$Global:ENVIRONMENT = $Environment
Write-Host("ENVIRONMENT: '$Global:ENVIRONMENT'")

# get environment configuration settings
$envConfigurationJson = "$PSScriptRoot\Config\$Global:ENVIRONMENT.json"
$Global:CONFIGURATION = Get-Content $envConfigurationJson | Out-String | ConvertFrom-Json
Write-Host("CONFIGURATION: '$Global:CONFIGURATION'")

# select subscription
$Global:SUBSCRIPTIONID = $Global:CONFIGURATION.subscriptionId
Write-Host("===========================================")

$Org = "https://dev.azure.com/kpn"
$Project = "ServiceNow IO"
$PipelineName = "B2B-LogicApp ASE"
$LogicAppName = "$Environment-$LogicAppFolder"
$LogicAppFolder = $Global:BASEPATH+"\"+$LogicAppFolder
Write-Host $LogicAppFolder

#========================================================================================================
# Deploy LogicApp 
#========================================================================================================
Write-Host "Starting LogicApp deployment for $LogicAppName on $Environment for branch $BranchName"

$LAcreate = $true

#========================================================================================================
# Get the Logic App Config
#========================================================================================================
Write-Host ("======================================================================================")
Write-Host " - Reading config for $LogicAppName"
$LaSettingsConfig = "$LogicAppFolder\la-config.json" 
$LaSettings = Get-Content $LaSettingsConfig | ConvertFrom-Json
$ResourceGroupName = $LaSettings."resourceGroupName".replace('<env>', $Environment)
$StorageName = $LaSettings."storageName".replace('<env>', $Environment)
$AppServicePlanName = $LaSettings."appServicePlanName".replace('<env>', $Environment)
$AppServicePlanResourceGroupName = $LaSettings."appServicePlanResourceGroupName".replace('<env>', $Environment)
$AppInsights = $LaSettings."appInsights".replace('<env>', $Environment)

Write-Host("======================================================================================")
Write-Host "Starting LogicApp deployment for $LogicAppName on $ResourceGroupName"

#========================================================================================================
# Create Logic App if Not Exists
#========================================================================================================

try {
    Write-Host " - Checking Logic App $LogicAppName"

    $apps = az logicapp list --resource-group $ResourceGroupName --subscription $Global:SUBSCRIPTIONID | ConvertFrom-Json
    foreach ($app in $apps) {
        if ($app.name -eq $LogicAppName) {
            $LAcreate = $false
        }
    }
}
catch {
    Throw "ERROR: Something went wrong listing the Logic Apps on the resourcegroup"
}

if ($LAcreate) {
    #========================================================================================================
    # Check App Service plan, if not exists, create error and stop
    #========================================================================================================
    try {
        Write-Host " - Checking AppServicePlan $AppServicePlanName"

        $AppServicePlan = az appservice plan show  --name $AppServicePlanName  --resource-group $AppServicePlanResourceGroupName --subscription $Global:SUBSCRIPTIONID | ConvertFrom-Json
    }
    catch {
        Throw "ERROR: AppServicePlan $AppServicePlanName  does not exists, first create the AppServicePlan!"
    }

    #========================================================================================================
    # Create Storage
    #========================================================================================================

    try {
        Write-Host " - Creating Storage account $StorageName"

        $Storage = az storage account create --name $StorageName --resource-group $ResourceGroupName --sku "Standard_LRS" -l "westeurope" --min-tls-version "TLS1_2" --kind "Storage" --allow-blob-public-access "true" --only-show-errors --subscription $Global:SUBSCRIPTIONID
        $UpdateSetting = az storage account update -g $ResourceGroupName -n $StorageName --set defaultToOAuthAuthentication=true --only-show-errors  --subscription $Global:SUBSCRIPTIONID

        Write-Host " - Storage account $AccountName created"
    }
    catch {
        Throw "ERROR: storageaccount $StorageName not created"
    }

    #========================================================================================================
    # Create Logic App
    #========================================================================================================

    try{
        Write-Host " - Deploying Logic App $LogicAppName"

        $runTimeVersion = "~18"
        $LogicAppRes = az logicapp create --name $LogicAppName --resource-group $ResourceGroupName --plan $AppServicePlan.id --storage-account $StorageName --https-only true --disable-app-insights false --app-insights $AppInsights --runtime-version $runTimeVersion --subscription $Global:SUBSCRIPTIONID | ConvertFrom-Json

        Write-Host " - Logic App $LogicAppName created"
    } catch {
        Throw "ERROR: LogicApp: $LogicAppName not created"
    }

    #========================================================================================================
    # Create LogicApp Identity
    #========================================================================================================

    try {
        Write-Host " - Create identity for $LogicAppName"

        $Identity = az webapp identity assign -g $ResourceGroupName -n $LogicAppName --subscription $Global:SUBSCRIPTIONID | ConvertFrom-Json

        Write-Host " - Identity created for $LogicAppName"
    }
    catch {
        Throw "ERROR: Identity for $LogicAppName not created"
    }

    #========================================================================================================
    # Create KeyVault Policy for the logic app
    #========================================================================================================

    try {
        Write-Host " - Create KeyVault Policy for $LogicAppName"

        $Policy = az keyvault set-policy -n kai-$Environment-shared-kv --secret-permissions get list --object-id $Identity.principalId --subscription $Global:SUBSCRIPTIONID

        Write-Host " - Policy created for $LogicAppName"
    }
    catch {
        Throw "ERROR: Policy for $LogicAppName not created"
    }

    #========================================================================================================
    # Create Diagnostic Settings for the logic app
    #========================================================================================================

    try {
        Write-Host " - Create diagnostic settings for $LogicAppName"

        $sharedRG = "kai-$Environment-shared-monitor-rg"
        $workspace = az monitor log-analytics workspace show --resource-group $sharedRG --workspace-name "kai-$Environment-shared-loganalytics-ws" --subscription $Global:SUBSCRIPTIONID | ConvertFrom-Json
        $Diagnostics = az monitor diagnostic-settings create --resource $LogicAppRes.id -n 'KaiLogging' --logs "[{category:WorkflowRuntime,enabled:true},{category:FunctionAppLogs,enabled:true}]" --metrics "[{category:AllMetrics,enabled:false}]" --workspace $workspace.id --subscription $Global:SUBSCRIPTIONID

        Write-Host " - Diagnostic settings created for $LogicAppName"
    }
    catch {
        Throw "ERROR: Diagnostics for $LogicAppName not created"
    }

    #========================================================================================================
    # Set generic settings on the Logic App
    #========================================================================================================
    try {
        Write-Host " - Changing generic settings"

        $Config = az webapp config set --resource-group $ResourceGroupName --name $LogicAppName --use-32bit-worker-process false --always-on true --http20-enabled false  --subscription $Global:SUBSCRIPTIONID

        Write-Host " - Generic settings changed"
    }
    catch {
        Throw "ERROR: General settings for $LogicAppName not changed"
    }

    #========================================================================================================
    # Remove excess setting on the Logic App
    #========================================================================================================

    try {
        Write-Host " - Remove excess application settings"

        $Setting = az logicapp config appsettings delete --name $LogicAppName --resource-group $ResourceGroupName --setting-names AzureWebJobsDashboard --only-show-errors --subscription $Global:SUBSCRIPTIONID
        $Setting = az logicapp config appsettings delete --name $LogicAppName --resource-group $ResourceGroupName --setting-names MACHINEKEY_DecryptionKey --only-show-errors --subscription $Global:SUBSCRIPTIONID

        Write-Host " - Excess application settings removed"
    }
    catch {
        Write-Host " - Setting has NOT been removed"
    }
}
else {
    Write-Host " - Logic App $LogicAppName exists, skip deployment"
}
$endDate =(Get-Date)
$duration=$endDate-$startDate
$minutes=$duration.minutes
$seconds=$duration.Seconds
Write-Host "Finished Logic App deployment for $LogicAppName in $minutes : $seconds" -ForegroundColor Green


Write-Host ""
Write-Host("======================================================================================")