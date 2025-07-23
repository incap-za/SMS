#======================================================================
# Author:       CTP &TDN
# Date:         2024 January 18
# Description:  Deployment App Settings for a standard Logic App
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
#========================================================================================================
# Add modules
#========================================================================================================
Import-Module $PSScriptRoot\Modules\Module-Utils -Force -PassThru
Write-Host("######################################################################################")
$startDate =(Get-Date)

# setting global variables
$TempFolder = $PSScriptRoot
$Global:BASEPATH = $TempFolder.Replace("Deployment","Projects")
Write-Host("BASEPATH:    '$Global:BASEPATH'")
$Global:ENVIRONMENT = $Environment
Write-Host("ENVIRONMENT: '$Global:ENVIRONMENT'")
Write-Host("FOLDER:      '$LogicAppFolder'")

# get environment configuration settings
$envConfigurationJson = "$PSScriptRoot\Config\$Global:ENVIRONMENT.json"
$Global:CONFIGURATION = Get-Content $envConfigurationJson | Out-String | ConvertFrom-Json
Write-Host("CONFIGURATION: '$Global:CONFIGURATION'")
 
# select subscription
$Global:SUBSCRIPTIONID = $Global:CONFIGURATION.subscriptionId
Write-Host("===========================================")


$Org = "https://dev.azure.com/kpn"
$Project = "ServiceNow IO"
$PipelineName = "B2B-AppSettings ASE"
$LogicAppName = "$Environment-$LogicAppFolder"
$LogicAppFolder = $Global:BASEPATH+"\"+$LogicAppFolder

#========================================================================================================
# Deploy Application Setting(s)
#========================================================================================================
Write-Host "Starting LogicApp settings deployment for $LogicAppName on $Environment for branch $BranchName" -ForegroundColor Green
try{
    #========================================================================================================
    # Get the Logic App Config
    #========================================================================================================
    $LaSettingsConfig = "$LogicAppFolder\la-config.json"
    $LaSettings = Get-Content $LaSettingsConfig | ConvertFrom-Json

    $ResourceGroupName=$LaSettings."resourceGroupName".replace('<env>', $Environment)

    #========================================================================================================
    # Set App Settings
    #========================================================================================================

    $AppSettingsConfig = "$LogicAppFolder\appsettings.json"
    Write-Host("APPSETTINGS: '$AppSettingsConfig'")
    Write-Host "Setting Appsettings for $LogicAppName on resourcegroup $ResourceGroupName"

    # Get the appsettings
    $SettingsArray=@()
    try{
        $AppSettings = Get-Content $AppSettingsConfig | ConvertFrom-Json
        $AppSettings.psObject.Properties | ForEach-Object{
            $SettingObject =@{}
            $AppName = $_.Name
            $AppValue = $_.Value
            $AppvalueEnv = Get-ParameterObjectValue -value $AppValue # Get Environment value
            $SettingsArray += "`"$AppName=$AppValueEnv`""
            Write-Host " - Set $AppName with value $AppValueEnv"
        }    
        $Ret = az logicapp config appsettings set -g $ResourceGroupName -n $LogicAppName --settings @SettingsArray --subscription $Global:SUBSCRIPTIONID

    } catch {
        Write-Host ">>>> ERROR: Appsettings for $LogicAppName on $Environment Failed <<<<"
        Write-Host "$Error"
    }
} catch {
    Write-Host $Error
    Throw ">>>> ERROR: LogicApp settings deployment for $LogicAppName on $Environment for branch $BranchName Failed <<<<"
}
$endDate =(Get-Date)
$duration=$endDate-$startDate
$minutes=$duration.minutes
$seconds=$duration.Seconds
Write-Host "Finished appsettings deployment for $LogicAppName in $minutes : $seconds" -ForegroundColor Green

Write-Host("")
Write-Host("======================================================================================")

