#
# DeployApis.ps1
#
param(
    [Parameter(Mandatory=$true)]
	[ValidateSet("dev", "acc", "prd")]
	$Environment,

	[Parameter(Mandatory=$true)]
	$SwaggerFileName
)

#========================================================================================================
# Add modules
#========================================================================================================
$apiModule = Import-Module $PSScriptRoot\Modules\LogicAppsApi -Force -PassThru

#========================================================================================================

# stop execution as encounter any exception
$ErrorActionPreference = "Stop"

Write-Host("######################################################################################")
$startDate =(Get-Date)

# setting global variables
$Global:BASEPATH = $PSScriptRoot
Write-Host("BASEPATH: 	 '$Global:BASEPATH'")
$Global:ENVIRONMENT = $Environment
Write-Host("ENVIRONMENT: '$Global:ENVIRONMENT'")

# validate swagger file base location
$repoFilePath = (Get-Item $Global:BASEPATH).Parent.Parent.FullName
$swaggerPath  = "$repoFilePath\Projects\APIs\$SwaggerFileName"
Write-Host("SWAGGER: '	 '$swaggerPath'")
$isLocationExists = Test-Path "$repoFilePath\Projects\APIs\$SwaggerFileName" -PathType Leaf
if($isLocationExists -ne $true){
    Write-Host "Not valid swagger file path. Specify correct 'SwaggerFileName' argument!" -ForegroundColor Red
    return
}

# getting environment setting file
$envSetting = Get-Content "$Global:BASEPATH\Config\$Global:ENVIRONMENT.json" | Out-String | ConvertFrom-Json


# getting API Management context
$Script:apimContext = New-AzApiManagementContext -ResourceGroupName $envSetting.apimResourceGroupName -ServiceName $envSetting.apimId

Write-Host("Calling API module Init ...")
#& $apiModule {Init -apimContext $Script:apimContext}
Init -apimContext $Script:apimContext

# get api name from swagger file path
$apiId = $SwaggerFileName.TrimEnd(".json")
# make it also possible to deploy .yaml files
$apiId = $apiId.TrimEnd(".yaml")
Write-Host("Calling API module ImportSwagger for API Id '$apiId' ...")
ImportSwagger -apiId $apiId -swaggerPath $swaggerPath -apiServiceUrl $envSetting.serviceUrl -environmentLogicApp $envSetting.environmentLogicApp -subscriptionId $envSetting.subscriptionId -apimResourceGroup $envSetting.apimResourceGroupName -apimName $envSetting.apimId

$endDate =(Get-Date)
$duration=$endDate-$startDate
$minutes=$duration.minutes
$seconds=$duration.Seconds
Write-Host "Finished API deployment for $SwaggerFileName in $minutes : $seconds" -ForegroundColor Green
Write-Host ""
Write-Host("======================================================================================")