#
# DeployProducts.ps1
# 
# NOTE: Was cleaned up when Ashutush left team; recreated 2020-03-09 to enable manual deployment of only product (especially for NoAuthProduct)
#		THIS IS STILL NOT WORKING FULLY!!!!!
#		LATER ADJUSTED DeployApiManagement.ps1 TO INCLUDE BasicAuthProduct + BasicAuthProductPolicy
#		THEREFORE NO LONGER NEEDED?!
#		To call: 
#			Set-Location "$gitDirectory\APIManagement"
#			.\DeployProducts -Environment $Environment -ProductType "noauth"
#

param(
    [Parameter(Mandatory=$true)]
	[ValidateSet("dev", "acc", "prd")]
	$Environment,

	[Parameter(Mandatory=$true)]
	[ValidateSet("basicauth","paramauth","headerauth","other")]
	$ProductType,

	[switch]$DeployFunctionApp = $false
)

# stop execution as encounter any exception
$ErrorActionPreference = "Stop"

#========================================================================================================
# Add modules
#========================================================================================================
$apiModule1 = Import-Module $PSScriptRoot\Modules\BasicAuthProduct -Force -PassThru
# added 2020-03-09
$apiModule2 = Import-Module $PSScriptRoot\Modules\ParamAuthProduct -Force -PassThru
# added 2021-02-09
$apiModule3 = Import-Module $PSScriptRoot\Modules\HeaderAuthProduct -Force -PassThru
#========================================================================================================

# stop execution as encounter any exception
$ErrorActionPreference = "Stop"

# setting global variables
$Global:BASEPATH = $PSScriptRoot
Write-Host("BASEPATH: '$Global:BASEPATH'")
$Global:ENVIRONMENT = $Environment
Write-Host("ENVIRONMENT: '$Global:ENVIRONMENT'")


##################################
# BEGIN added 2020-03-09

# getting environment setting file
$envSetting = Get-Content "$Global:BASEPATH\Config\$Global:ENVIRONMENT.json" | Out-String | ConvertFrom-Json

Write-Host("Selecting subscription " + $envSetting.subscriptionId)
Select-AzSubscription -SubscriptionID $envSetting.subscriptionId

# getting API Management context
$apimContext = New-AzApiManagementContext -ResourceGroupName $envSetting.apimResourceGroupName -ServiceName $envSetting.apimId
Write-Host($apimContext)

# END added 2020-03-09
##################################


if($ProductType.ToLowerInvariant() -eq "basicauth"){

	if($DeployFunctionApp){
		# build and deploy Azure function package
	}
	
	# create basic authentication product based on environment and setting available in Config\{{env}}.json file
	Write-Host("Creating basic authentication product with policies ...")
#	Update-Product-BasicAuth-Policy -environment $Environment
	Update-Product-BasicAuth-Policy -apimContext $apimContext
}


##################################
# BEGIN added 2020-03-09
if($ProductType.ToLowerInvariant() -eq "paramauth"){

	if($DeployFunctionApp){
		# build and deploy Azure function package
	}

	# create parameter authentication product based on environment and setting available in Config\{{env}}.json file
	Write-Host("Creating parameter-authentication product with policies ...")
	Update-Product-ParamAuth-Policy -apimContext $apimContext
}
# END added 2020-03-09
##################################
# BEGIN added 2021-02-09

if($ProductType.ToLowerInvariant() -eq "headerauth"){

	if($DeployFunctionApp){
		# build and deploy Azure function package
	}

	# create header authentication product based on environment and setting available in Config\{{env}}.json file
	Write-Host("Creating header-authentication product with policies ...")
	Update-Product-HeaderAuth-Policy -apimContext $apimContext
}
# END added 2021-02-09
##################################
