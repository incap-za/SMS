#
# BasicAuthProduct.psm1
#

#===================================================================================================
# Use this function to update basic authentication Product policy
#
# NOTE: Was cleaned up when Ashutush left team; recreated 2020-03-09 to enable manual deployment of only product (especially for NoAuthProduct)
#		THIS IS STILL NOT WORKING FULLY!!!!!
#		LATER ADJUSTED DeployApiManagement.ps1 TO INCLUDE BasicAuthProduct + BasicAuthProductPolicy
#		THEREFORE NO LONGER NEEDED?!
#===================================================================================================
function Update-Product-BasicAuth-Policy{
	param(
		# provide environment type from valid enum set
		[Parameter(Mandatory=$true)]
		$apimContext
	)
	
	##################################
	# BEGIN added 2020-03-09

	# load basic auth product policy
	$basicAuthPolicy = Get-Content "$Global:BASEPATH\Policies\BasicAuthProductPolicy.xml" | Out-String
	# get response-headers policy
	$responseHeaders = Get-Content "$Global:BASEPATH\Config\ResponseHeader.data" | Out-String
	# set response-headers section in raw Policy
	$basicAuthPolicy = $basicAuthPolicy.Replace("{{response-headers}}", $responseHeaders)
	
	# END added 2020-03-09
	##################################

	# set product policy
	# Change 2021-11-23  removed commented line as it was breaking the command
	Set-AzApiManagementPolicy -Context $apimContext -ProductId "basicauthproduct" `
			-Policy $basicAuthPolicy `
			-Format application/vnd.ms-azure-apim.policy.raw+xml `
			-Verbose -ErrorVariable ErrorMessages -PassThru 

}

Export-ModuleMember -Function "Update-Product-BasicAuth-Policy"