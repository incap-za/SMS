#
# DeployApiManagement.ps1
#
param(
    [Parameter(Mandatory=$true)]
	[ValidateSet("dev", "acc", "prd")]
	$Environment,

	[switch]$UploadCertificate
)

# stop execution as encounter any exception
$ErrorActionPreference = "Stop"

#========================================================================================================
# Add modules
#========================================================================================================
Import-Module $PSScriptRoot\Modules\KeyVault -Force -PassThru

#========================================================================================================

# setting global variables
$Global:BASEPATH = $PSScriptRoot
Write-Host("BASEPATH: '$Global:BASEPATH'")
$Global:ENVIRONMENT = $Environment
Write-Host("ENVIRONMENT: '$Global:ENVIRONMENT'")

# getting environment setting file
$envSetting = Get-Content "$Global:BASEPATH\Config\$Global:ENVIRONMENT.json" | Out-String | ConvertFrom-Json

Write-Host("Selecting subscription " + $envSetting.subscriptionId)
Select-AzSubscription -SubscriptionID $envSetting.subscriptionId

#========================================================================================================
# Declare private functions
#========================================================================================================
function SetSecretCertificate{
	param(
		[Parameter(Mandatory=$true)]
		[string]$ConfirmationMessage,

		[string]$KeyVaultSecret
	)

	$confirmation = Read-Host "$ConfirmationMessage [y/n]"
	if($confirmation.ToUpperInvariant() -eq 'Y'){
		$secretName = $KeyVaultSecret
		while([string]::IsNullOrEmpty($secretName))
		{
			$secretName = Read-Host "Provide key vault secret name"
		}

		$pfxFilePath = ""
		while($true)
		{
			$pfxFilePath = Read-Host "Provide pfx file path"
			if([string]::IsNullOrEmpty($pfxFilePath)){
				$pfxFilePath = "Invalid_Path"
			}

			if((Test-Path -Path $pfxFilePath -PathType Leaf) -and $pfxFilePath.EndsWith(".pfx")){
				break
			}
		}
		
		$pfxFilePassword = ""
		while([string]::IsNullOrEmpty($pfxFilePassword))
		{
			$password = Read-Host "Provide pfx file password" -AsSecureString
			$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
			$pfxFilePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

			#$pfxFilePassword = (New-Object PSCredential "user", $password).GetNetworkCredential().Password
		}

		Set-SecretCertificate -SecretName $secretName -PfxFilePath $pfxFilePath -PfxFilePassword $pfxFilePassword
	}
}
#========================================================================================================

# upload certificate to key vault
if($UploadCertificate){
	$keyVaultSecretPrefex = "b2b"
	if ($Global:ENVIRONMENT.ToUpperInvariant() -ne "PRD") {
		$keyVaultSecretPrefex = "b2b$Global:ENVIRONMENT"
	}
	
	# set proxy certificate to KV
	SetSecretCertificate -ConfirmationMessage "Upload 'Proxy' host certificate to KeyVault?" -KeyVaultSecret "$keyVaultSecretPrefex-connect"
	
	# domain portal is not available for PRD environment 
	if ($Global:ENVIRONMENT.ToUpperInvariant() -ne "PRD") {
		# set portal certificate to KV
		SetSecretCertificate -ConfirmationMessage "Upload 'Portal' host certificate to KeyVault?" -KeyVaultSecret "$keyVaultSecretPrefex-connect-portal"
	}	
}

# load API policy
$apiPolicy = Get-Content "$Global:BASEPATH\Policies\ApiPolicy.xml" | Out-String

# get ip-filter policy
$ipFilter = Get-Content "$Global:BASEPATH\Config\IP-Filter\$Global:ENVIRONMENT.xml" | Out-String

# set ip-filter section in raw API Policy
$apiPolicy = $apiPolicy.Replace("{{ip-filter}}", $ipFilter)

# get response-headers policy
$responseHeaders = Get-Content "$Global:BASEPATH\Config\ResponseHeader.data" | Out-String

# load basic auth product policy
$basicAuthPolicy = Get-Content "$Global:BASEPATH\Policies\BasicAuthProductPolicy.xml" | Out-String
# set response-headers section in raw Policy
$basicAuthPolicy = $basicAuthPolicy.Replace("{{response-headers}}", $responseHeaders)

# load param auth product policy
$paramAuthPolicy = Get-Content "$Global:BASEPATH\Policies\ParamAuthProductPolicy.xml" | Out-String
# set response-headers section in raw Policy
$paramAuthPolicy = $paramAuthPolicy.Replace("{{response-headers}}", $responseHeaders)

# load header auth product policy
$headerAuthPolicy = Get-Content "$Global:BASEPATH\Policies\HeaderAuthProductPolicy.xml" | Out-String
# set response-headers section in raw Policy
$headerAuthPolicy = $headerAuthPolicy.Replace("{{response-headers}}", $responseHeaders)

Write-Host("Deploying API Management ...")
# deploy API Management infra and api policy - IP White-listing and Custom domain certificates
New-AzResourceGroupDeployment -Name ('apim-deployment-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
		-ResourceGroupName $envSetting.apimResourceGroupName `
        -TemplateFile "$Global:BASEPATH\ARMTemplates\apim.json" `
        -TemplateParameterFile "$Global:BASEPATH\ARMTemplates\Parameters\apim.parameters.$Global:ENVIRONMENT.json" `
        -apiPolicy $apiPolicy `
		-basicAuthPolicy $basicAuthPolicy `
		-paramAuthPolicy $paramAuthPolicy `
		-headerAuthPolicy $headerAuthPolicy `
        -Mode Incremental -Force -Verbose `
        -ErrorVariable ErrorMessages
