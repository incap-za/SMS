#
# DeployApimFunctionApp.ps1
# deploy authorization function app
#
param(
    [Parameter(Mandatory=$true)]
	[ValidateSet("dev", "acc", "prd")]
	$Environment
)

# stop execution as encounter any exception
$ErrorActionPreference = "Stop"

# setting global variables
$Global:BASEPATH = $PSScriptRoot
Write-Host("BASEPATH: '$Global:BASEPATH'")
$Global:ENVIRONMENT = $Environment
Write-Host("ENVIRONMENT: '$Global:ENVIRONMENT'")

# getting environment setting file
$envSetting = Get-Content "$Global:BASEPATH\Config\$Global:ENVIRONMENT.json" | Out-String | ConvertFrom-Json

Write-Host("Selecting subscription " + $envSetting.subscriptionId)
Select-AzSubscription -SubscriptionID $envSetting.subscriptionId

Write-Host("Deploying authorization function app ...")
# deploy authorization function app infra
New-AzResourceGroupDeployment -Name ('apim-funcapp-deployment-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
		-ResourceGroupName $envSetting.apimResourceGroupName `
		-TemplateFile "$Global:BASEPATH\ARMTemplates\apimFunctionApp.json" `
		-TemplateParameterFile "$Global:BASEPATH\ARMTemplates\Parameters\apimFunctionApp.parameters.$Global:ENVIRONMENT.json" `
		-Mode Incremental -Force -Verbose `
		-ErrorVariable ErrorMessages