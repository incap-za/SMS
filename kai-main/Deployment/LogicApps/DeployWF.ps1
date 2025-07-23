#======================================================================
# Author:       CTP &TDN
# Date:         2024 January 18
# Description:  Deployment of Artifacts for Standard Logic App  
#               via ZIP deployment & Azure CLI
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
$Global:BASEPATH = $PSScriptRoot.Replace("Deployment","Projects")
Write-Host("BASEPATH: '$Global:BASEPATH'")
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
$PipelineName = "B2B-Workflow ASE"
$LogicAppName = "$Environment-$LogicAppFolder"
$LogicAppFolder = $Global:BASEPATH+"\"+$LogicAppFolder

#========================================================================================================
# Deploy Workflow(s)
#========================================================================================================
Write-Host "Starting Workflow artifacts deployment for $LogicAppName on $Environment for branch $BranchName" -ForegroundColor Green
try{
    Write-Host("======================================================================================")
    Write-Host("Converting workflow files")
    $laConfig = Get-Content $LogicAppFolder"\la-config.json" |ConvertFrom-Json
    $resourceGroupName = $laConfig.resourceGroupName.Replace("<env>",$Environment)

    # Get all the workflow folders
    $Folders = Get-ChildItem -Path $LogicAppFolder -Recurse -Directory -Force -ErrorAction SilentlyContinue | Select-Object FullName
    foreach($Folder in $Folders){
        #Write-Host $Folder.FullName
        if($Folder.FullName -match '-wf$'){
            # workflow folders should end with '-wf'
            Convert-Workflow -Environment $Global:ENVIRONMENT -WorkflowFolder $Folder.FullName
        }
    }

    Write-Host("======================================================================================")
    Write-Host("Converting parameters file")
    Convert-Parameters -Environment $Global:ENVIRONMENT -LogicAppFolder $LogicAppFolder

    Write-Host("======================================================================================")
    Write-Host("Getting api connections")
    $ConnectionFile = $LogicAppFolder +"\connections.json"
    Write-Host("$ConnectionFile")
    $ApiConnection = "$PSScriptRoot\Config\$resourceGroupName-apiconnection.json"
    if([System.IO.File]::Exists($ApiConnection)){
        Write-Host("$ApiConnection")
        $orgConnFile = Get-Content $ConnectionFile -Raw 
        $updInfo = Get-Content $ApiConnection
        $updConNFile = $orgConnFile.replace('"managedApiConnections": {},',$updInfo)
        Write-Host $updConNFile
        Set-Content -Path $ConnectionFile $updConNFile
        Write-Host("APi connections updated")
       
    } else {
        Write-Host("No API connections to update for resourcegroup $resourceGroupName")
    }

    Write-Host("======================================================================================")
    Write-Host("Creating ZIP file")
    $ZipFile = $LogicAppFolder+"\zipfile.zip"
    Compress-Archive -Path $LogicAppFolder\* -DestinationPath $ZipFile -Force

    Write-Host("======================================================================================")
    Write-Host("Deploy ZIP file")
    az logicapp deployment source config-zip --name $LogicAppName --resource-group $resourceGroupName --src $ZipFile --subscription $Global:SUBSCRIPTIONID 

} catch {
    Write-Host $Error
    Throw ">>>> ERROR: Workflow artifacts deployment for $LogicAppName on $Environment for branch $BranchName Failed <<<<"
}
#}
$endDate =(Get-Date)
$duration=$endDate-$startDate
$minutes=$duration.minutes
$seconds=$duration.Seconds
Write-Host "Finished workflow artifacts deployment for $LogicAppName in $minutes : $seconds" -ForegroundColor Green

Write-Host ""
Write-Host("======================================================================================")

