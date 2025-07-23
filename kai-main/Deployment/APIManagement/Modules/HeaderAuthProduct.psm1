#
# HeaderAuthProduct.psm1
#

#===================================================================================================
# Use this function to update Product policy with authentication on parameters (initially for Zsmart callback-url only)
#
# NOTE: Was cleaned up when Ashutush left team; recreated 2020-03-09 to enable manual deployment of only product (especially for HeaderAuthProduct)
#		THIS IS STILL NOT WORKING FULLY!!!!!
#		LATER ADJUSTED DeployApiManagement.ps1 TO INCLUDE HeaderAuthProduct + HeaderAuthProductPolicy
#		THEREFORE NO LONGER NEEDED?!
#===================================================================================================
function Update-Product-HeaderAuth-Policy{
	param(
		# provide APIM context
		[Parameter(Mandatory=$true)]
		$apimContext
	)

	##################################
	# BEGIN added 2020-03-09
	
	Try
		{
			$Product = Get-AzApiManagementProduct -Context $apimContext -ProductId "headerauthproduct" -ErrorAction Stop
			Write-Host('Configuring existing product:')
			Set-AzApiManagementProduct -Context $apimContext -ProductId "headerauthproduct" -Title "HeaderAuthProduct" -Description "Test for product with authentication on soap Header, initially only to be used for Zsmart a-sync responses" -LegalTerms "Only to be used for Zsmart a-sync responses!" -SubscriptionRequired $False -State "Published"
		}
	Catch
		{
			#$ErrorMessage = $_.Exception.Message
			#Write-Host('Error:'+$ErrorMessage)
			Write-Host('New product to be created:')
			New-AzApiManagementProduct -Context $apimContext -ProductId "headerauthproduct" -Title "HeaderAuthProduct" -Description "Test for product with authentication on soap Header, initially only to be used for Zsmart a-sync responses" -LegalTerms "Only to be used for Zsmart a-sync responses!" -SubscriptionRequired $False -State "Published"
		}

	Write-Host($Global:BASEPATH)
	# load basic auth product policy
	$AuthPolicy = Get-Content "$Global:BASEPATH\Policies\HeaderAuthProductPolicy.xml" | Out-String
#	Write-Host($AuthPolicy)

	# get response-headers policy
	$responseHeaders = Get-Content "$Global:BASEPATH\Config\ResponseHeader.data" | Out-String
#	Write-Host($responseHeaders)

	# set response-headers section in raw Policy
	$AuthPolicy = $AuthPolicy.Replace("{{response-headers}}", $responseHeaders)
#	Write-Host($AuthPolicy)
	
	# END added 2020-03-09
	##################################
	
	Write-Host('Setting product policy:')
	# set product policy
	Set-AzApiManagementPolicy -Context $apimContext -ProductId "headerauthproduct" `
			-Policy $AuthPolicy `
			-Format application/vnd.ms-azure-apim.policy.raw+xml `
			-Verbose -ErrorVariable ErrorMessages -PassThru

}

Export-ModuleMember -Function "Update-Product-HeaderAuth-Policy"