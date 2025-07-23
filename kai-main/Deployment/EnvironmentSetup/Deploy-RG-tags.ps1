#======================================================================
# Author:       CTP & TDN
# Date:         2025 June 26
# Description:  Creation Resource Groups with necessary tags
#
# Parameters:
#   - Environment:      The environment where to install
#   - Name:             The name of the resource group
#======================================================================
#
# Deploy-RG.ps1
#
param (
    [ValidateSet("dev","acc","prd")]
    [Parameter(Mandatory=$true)]
    [string]$Environment,

	[Parameter(Mandatory=$true)]
    [string]$Name
)

# stop execution as encounter any exception
$ErrorActionPreference = "Stop"
Write-Host("######################################################################################")

# setting global variables
$Global:BASEPATH = $PSScriptRoot
Write-Host("BASEPATH: '$Global:BASEPATH'")
$Global:ENVIRONMENT = $Environment
Write-Host("ENVIRONMENT: '$Global:ENVIRONMENT'")

# get environment configuration settings
$envConfigurationJson = "$Global:BASEPATH\Config\$Global:ENVIRONMENT.json"
$Global:CONFIGURATION = Get-Content $envConfigurationJson | Out-String | ConvertFrom-Json
Write-Host("CONFIGURATION: '$Global:CONFIGURATION'")

# select subscription
$Global:SUBSCRIPTIONID = $Global:CONFIGURATION.subscriptionId
Write-Host("Selecting subscription '$Global:SUBSCRIPTIONID'")
# select location
$Global:LOCATION = $Global:CONFIGURATION.location
Write-Host("Selecting location '$Global:LOCATION'")

#========================================================================================================
# Collect tags-settings from environment-configuration file
#========================================================================================================
# Get default Tags from Environment config file and convert it into an Array of tags ("tag=value") format
$Tags = $Global:CONFIGURATION.tags |ConvertTo-Json
$TagsArray = @()
(ConvertFrom-Json $Tags).psobject.properties |Foreach {$TagsArray+=$_.Name+"="+$_.Value}

# Force name to lowercase
$Name = $Name.ToLower()

#========================================================================================================
# Check if Resource Group already exists
#========================================================================================================
try{
    Write-Host ("======================================================================================")
    Write-Host " - Checking Resource group $Name"
    $rgExists = az group exists --subscription $Global:SUBSCRIPTIONID --name $Name
    Write-Host " - Resource group check output: $rgExists"
} catch {
    Throw "ERROR: Resource group: check existing failed"
}

#========================================================================================================
# Create Resource Group if Not Exists
#========================================================================================================
if($rgExists -eq "false"){
    try{
        Write-Host " - Creating Resource group $Name"
        az group create --subscription $Global:SUBSCRIPTIONID --location $Global:LOCATION --name $Name --tags $TagsArray
        Write-Host " - Resource group $Name created"
    } catch {
        Throw "ERROR: Resource group: $Name not created"
    }
}
else {
    try{
        Write-Host("Resource Group $Name already exists - updating tags")
        az group update --subscription $Global:SUBSCRIPTIONID --name $Name --tags $TagsArray
        Write-Host " - Resource group $Name tags updated"
    } catch {
        Throw "ERROR: Resource group: $Name not updated"
    }
}

Write-Host ""
Write-Host("======================================================================================")