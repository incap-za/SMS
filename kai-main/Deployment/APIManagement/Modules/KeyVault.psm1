#
# KeyVault.psm1
#

#===================================================================================================
# Upload certificate to KeyVault
#===================================================================================================
function Set-SecretCertificate{
	param(
		[Parameter(Mandatory=$true)]
		[string]$SecretName,

        [Parameter(Mandatory=$true)]
		[string]$PfxFilePath,
		
		[Parameter(Mandatory=$true)]
		[string]$PfxFilePassword
	)
	
	# validate pfx file path
	$isFileExists = Test-Path $PfxFilePath -PathType Leaf
	if($isFileExists -ne $true){
		Write-Host "Not valid pfx file path. Please provide correct 'PfxFilePath' argument!" -ForegroundColor Red
		Throw
	}

	try{
		# import pfx file to certificate collection object
		$flag = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
		$collection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection 
		$collection.Import($PfxFilePath, $PfxFilePassword, $flag)

		# export certificate to pksc12 content type
		$pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12
		$clearBytes = $collection.Export($pkcs12ContentType)

		# convert certificate content to base64 (To upload to key vault)
		$fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
		$SecretValue = ConvertTo-SecureString -String $fileContentEncoded -AsPlainText -Force
	}
	catch{
		Write-Host "Unable to set key vault secret..." -ForegroundColor Red
        Throw $Error[0].Exception
	}

	# set KV secret value as certificate (content type as application/x-pkcs12)
	$secretContentType = 'application/x-pkcs12'
	Write-Host "Setting key vault secret $SecretName ..."
	Set-AzKeyVaultSecret -VaultName "kai-$Global:ENVIRONMENT-shared-kv" -Name $SecretName -SecretValue $SecretValue -ContentType $secretContentType

}

Export-ModuleMember -Function "Set-SecretCertificate"