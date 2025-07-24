#
# LogicAppsApi.psm1
#

# Script level variables
$apimContext;

# initialize script
function Init{
	param(
        [Parameter(Mandatory=$true)]
		$apimContext
	)

	Write-Host("Init Logic App Api ...")
	$Script:apimContext = $Local:apimContext
}

# Function used to import swagger file from local disk to Azure API Management
# Import function will create API if not exists
# Import function will update API if exists
function ImportSwagger{
	param(
		# API Id/Name
		[Parameter(Mandatory=$true)]
		[string]$apiId,

		# Swagger file full path
        [Parameter(Mandatory=$true)]
        [string]$swaggerPath,

		# api service URL, this will override swagger file host entry
        [Parameter(Mandatory=$true)]
        [string]$apiServiceUrl,

		# environment used for naming of the LogicApps and resoiurcegroups
        [Parameter(Mandatory=$true)]
        [string]$environmentLogicApp,

		# subscription ID used for retrieving workflow callback url
		[Parameter(Mandatory=$true)]
        [string]$subscriptionId,

		# APIM Resourcegroup
		[Parameter(Mandatory=$true)]
		[string]$apimResourceGroup,

		# APIM Name
		[Parameter(Mandatory=$true)]
		[string]$apimName
    )
	# For az cli
	$Script:resourceGroup = $apimResourceGroup
	$Script:apimName = $apimName
	Write-Host("======================================================================================")
	# getting mapping settings based on environment
	$repoFilePath = (Get-Item $Global:BASEPATH).Parent.Parent.FullName
	$mappingSettings = Get-Content "$repoFilePath\Projects\APIs\_apiMappings.json" | Out-String | ConvertFrom-Json
	$apiSetting = $mappingSettings.apis | Where {$_.id -eq $apiId}
	if([string]::IsNullOrEmpty($apiSetting)){
		# validate api - swagger file name exists in apiMapping json
		Write-Host " >>> Api $apiId does not exists in mapping settings. Please check and try again ..." -ForegroundColor Red
		return
	}
	if($apiSetting.version -eq "openapi"){
			Write-Host(" - Importing openapi file to Azure APIM")
			# NOTE: assigning parameters (starting with --) with = to ensure content start with hyphen is fine. Only --path gave issues assigning like that, so ignored it.
			$apiManagementApi = az apim api import --resource-group=$Script:resourceGroup -n $Script:apimName --subscription=$subscriptionId --specification-format="OpenApi" --specification-path $swaggerPath --path $apiSetting.path --api-id=$apiId
		}else{
			Write-Host(" - Importing swagger file to Azure APIM")
			# NOTE: assigning parameters (starting with --) with = to ensure content start with hyphen is fine. Only --path gave issues assigning like that, so ignored it.
			$apiManagementApi = az apim api import --resource-group=$Script:resourceGroup -n $Script:apimName --subscription=$subscriptionId --specification-format="Swagger" --specification-path=$swaggerPath --path $apiSetting.path --api-id=$apiId
		}
	#Write-Host($apiManagementApi)
	if($apiManagementApi){
		Write-Host(" - Swagger file imported to API: $apiId")
	}
	else{
		Write-Host " >>> Unable to process with provided swagger file $swaggerPath. Correct and try again ..." -ForegroundColor Red
		return
	}
	
	# update Api host detail
	Write-Host " - Update Host details to $apiServiceUrl"
	# NOTE: assigning parameters (starting with --) with = to ensure content start with hyphen is fine. Only --path gave issues assigning like that, so ignored it.
	$result = az apim api update --resource-group=$Script:resourceGroup -n $Script:apimName --subscription=$subscriptionId --path $apiSetting.path --api-id=$apiId --set ServiceUrl=$apiServiceUrl
	# getting operations for the Api - APIM
	$apiOperations = az apim api operation list --resource-group=$Script:resourceGroup -n $Script:apimName --api-id=$apiId --subscription=$subscriptionId | ConvertFrom-Json
	
	# retrieve operation settings from mapping file and process against APIM Api
	foreach($operationSetting in $apiSetting.operations){
		Write-Host "--------------------------------------------------"
		Write-Host " - Deploying operation $($operationSetting.id)"
		# validate api operation id exists in APIM Api
		$operationExists = $apiOperations | Where {$_.name -eq $operationSetting.id}
		if([string]::IsNullOrEmpty($operationExists.Id)){
			continue
		}
		$logicAppName = $operationSetting.logicAppName -replace "{{env}}", $environmentLogicApp 
		$logicAppResourceGroupName = $operationSetting.logicAppResourceGroupName -replace "{{env}}", $environmentLogicApp 
		$logicAppWorkflowName = $operationSetting.logicAppWorkflowName -replace "{{env}}", $environmentLogicApp 
		$logicAppWorkflowTriggerName = $operationSetting.logicAppWorkflowTriggerName -replace "{{env}}", $environmentLogicApp 
		
		
		# retrieve logic app signature and base url for manula/specified trigger type
		$triggerMethodName = $logicAppWorkflowTriggerName
		if(![string]::IsNullOrEmpty($operationSetting.logicAppTriggerMethod)){
			$triggerMethodName = "manual-" + $operationSetting.logicAppTriggerMethod.ToLowerInvariant()
		}
		$aseName = "kai-" + $environmentLogicApp + "-shared-ase"
                $workflowCallRestCall = "/subscriptions/" + $subscriptionId + "/resourceGroups/" + $logicAppResourceGroupName + "/providers/Microsoft.Web/sites/" + $logicAppName +  "/hostruntime/runtime/webhooks/workflow/api/management/workflows/" + $logicAppWorkflowName + "/triggers/" + $triggerMethodName  + "/listCallbackUrl?api-version=2022-09-01"

                # retry fetching the callback url as workflow deployment can take some time
                $logicAppCallbackUrl = $null
                for($i = 0; $i -lt 5; $i++){
                        try{
                                $logicAppCallbackUrl = az rest  --uri=$workflowCallRestCall --method POST | ConvertFrom-Json
                                $logicAppCallbackUrl = $logicAppCallbackUrl.value
                                if(![string]::IsNullOrEmpty($logicAppCallbackUrl)) { break }
                        }catch{
                                # ignore and retry
                        }
                        Start-Sleep -Seconds 15
                }

                if(![string]::IsNullOrEmpty($logicAppCallbackUrl))
                {
                        $logicAppUri  = [System.Uri]($logicAppCallbackUrl);
                        $serviceUrl = "https://" + $logicAppUri.Host + "/" + $logicAppUri.AbsolutePath
                        $accessKeyValue = $logicAppUri.Query.Substring($logicAppUri.Query.LastIndexOf("&sig=") + 5)
                }
                else{
                        # return if no callback url found!
                        Write-Host " >>> Unable to retrieve logic app trigger callback url" -ForegroundColor Red
                        return
                }
		
		# create/update backend service
		Write-Host(" - Creating Backend to Logic App Workflow ...")       
		$backendId = CreateOperationBackendService -apiId $apiId -apiOperationId $operationSetting.id -subscriptionId $subscriptionId  -logicApp $logicAppName -LaResourceGroup $logicAppResourceGroupName -serviceUrl $serviceUrl

		# update operation policy
		Write-Host(" - calling UpdateOperationPolicy ...")
		UpdateOperationPolicy -apiId $apiId -apiOperationId $operationSetting.id -logicAppBackendId $backendId.ToString() -logicAppKey $accessKeyValue -logicAppTriggerMethod $operationSetting.logicAppTriggerMethod -logicAppWorkflowTriggerName $logicAppWorkflowTriggerName -logicAppTriggerRelativePaths $operationSetting.logicAppTriggerRelativePaths -logicAppTriggerRelativePathToQuery $operationSetting.logicAppTriggerRelativePathToQuery  -subscriptionId $subscriptionId
	}
	
	# assign api to basic authentication product
	Write-Host "--------------------------------------------------"
	Write-Host(" - calling AddApiToProduct ...")
	foreach($product in $apiSetting.products){
		Write-Host(" - Setting Api to Product " + $product.id + " ...")
		AddApiToProduct -apiId $apiId -productId $product.id -subscriptionId $subscriptionId
	}
	Write-Host("======================================================================================")
	

}

# create or update APIM backend service 
function CreateOperationBackendService{
	param(
		# API id/name
		[Parameter(Mandatory=$true)]
		[string]$apiId,
		
		# Operation id/name
		[Parameter(Mandatory=$true)]
        [string]$apiOperationId,

		# LogicApp name
		[Parameter(Mandatory=$true)]
        [string]$logicApp,

		# LogicApp RG name
		[Parameter(Mandatory=$true)]
        [string]$LaResourceGroup,

		# Logic App Absolute uri
        [Parameter(Mandatory=$true)]
        [string]$serviceUrl,

		# subscriptionId
        [Parameter(Mandatory=$true)]
        [string]$subscriptionId

    )
	
	# create/update backend
	$backendId = "bla-$apiId-$apiOperationId"	
	$resourceId = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$LaResourceGroup/providers/Microsoft.Web/sites/$logicApp"
	$uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$Script:resourceGroup/providers/Microsoft.ApiManagement/service/$Script:apimName/backends/$backendId"
	$uri = $uri + "?api-version=2021-08-01"
	$jsonObj = @{
		'properties'=@{
			'protocol'= 'http'
			'title' = $backendId 
			'resourceId'= $resourceId 
			'url'= $serviceUrl 
		}
	}
	$json = ($jsonObj | ConvertTo-Json -Compress).Replace('"', '\"') 

	$result = az rest --method PUT --uri $uri --body $json
	$result = $result | ConvertFrom-Json
	if($result.name -eq $backendId){
		Write-Host(" - API backend '$backendId' created")
	} else {
		Write-Host(" >>> Error Creating Backend '$backendId'")
		continue
	}
		# return backend id
	return $backendId
		
}

# Update or create policy for Logic App API Operations
function UpdateOperationPolicy{
	param(
		# API id/name
		[Parameter(Mandatory=$true)]
		[string]$apiId,
		
		# Operation id/name
		[Parameter(Mandatory=$true)]
        [string]$apiOperationId,
		
		# Logic app backend id
        [Parameter(Mandatory=$true)]
        [string]$logicAppBackendId,

		# Logic app access key
        [Parameter(Mandatory=$true)]
        [string]$logicAppKey,
		
		# Logic app trigger method name
		[Parameter(Mandatory=$true)]
        [string]$logicAppWorkflowTriggerName,

		# Logic app trigger method
        [string]$logicAppTriggerMethod,

		# Logic app trigger relative path - this is same as API operation path parameters name
		# comma separated value
		# e.g.: id,name
        [string]$logicAppTriggerRelativePaths,
    
		# Logic app trigger relative path to Query- this is same as API operation path parameters name
		# to be converted to a query paremeter, just one path parameter possible
		[string]$logicAppTriggerRelativePathToQuery,
		
		# subscriptionId
		[Parameter(Mandatory=$true)]
		[string]$subscriptionId
	)
	# create Named values for api operation policy
	$nv_logicAppKey_name = "bla_" + $apiId + "_" + $apiOperationId + "_key"
	$nv_logicAppKey_value = $logicAppKey
    
	$result = az apim nv create --display-name=$nv_logicAppKey_name --named-value-id=$nv_logicAppKey_name --value=$nv_logicAppKey_value --secret=true --resource-group=$Script:resourceGroup -n $Script:apimName --subscription=$subscriptionId | ConvertFrom-Json
	#Write-Host $result 
	if($result.displayName -eq $nv_logicAppKey_name){
		Write-Host " - Named Value '$nv_logicAppKey_name' created"
	} else {
		Write-Host " >>> ERROR Creating Name value pair $nv_logicAppKey_name"
	}
	

	# set logic app trigger method name
	$triggerMethod = "POST"
	$triggerMethodName = $logicAppWorkflowTriggerName
	if(![string]::IsNullOrEmpty($logicAppTriggerMethod)){
		$triggerMethod = $logicAppTriggerMethod.ToUpperInvariant()
		$triggerMethodName = "manual-" + $logicAppTriggerMethod.ToLowerInvariant()
	}
	
	# set rewrite-uri template value
	$template = "/?api-version=2022-05-01&amp;sp=/triggers/$triggerMethodName/run&amp;sv=1.0&amp;sig={{$nv_logicAppKey_name}}"
	if(![string]::IsNullOrEmpty($logicAppTriggerRelativePaths))
	{
		$parameter = ""
		foreach($relativePath in $logicAppTriggerRelativePaths.Split(","))
		{
			$parameter += "/$relativePath/{context.Request.MatchedParameters[""$relativePath""]}"
		}
		$template = "@($""$parameter/?api-version=2022-05-01&amp;sp=/triggers/$triggerMethodName/run&amp;sv=1.0&amp;sig={{$nv_logicAppKey_name}}"")"
	}

	# set rewrite path parameter to query parameter value
	$query = ""
	if(![string]::IsNullOrEmpty($logicAppTriggerRelativePathToQuery))
	{
		$query="<set-query-parameter name=""$logicAppTriggerRelativePathToQuery"" exists-action=""skip"">
		<value>@(context.Request.Url.Path.Substring(context.Request.Url.Path.LastIndexOf('/')+1))</value>
		</set-query-parameter>"
		Write-Host("transferring path parameter $LogicAppTriggerRelativePathToQuery to query parameter")
	}
	# get api policy template
	$apiPolicyFilePath = "$Global:BASEPATH\Policies\LogicAppApiOperationPolicy.xml"
	$policy = Get-Content $apiPolicyFilePath  | Out-String 
	
	# set HTTP method
	$policy = $policy.Replace("{{triggermethod}}", $triggermethod)
	# set logic app backend id
	$policy = $policy.Replace("{{logicapp-backend-id}}", $logicAppBackendId.ToString())
	# set rewrite-uri template
	$policy = $policy.Replace("{{template}}", $template)
	# set query
	$policy = $policy.Replace("{{path2query}}", $query)

	$uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$Script:resourceGroup/providers/Microsoft.ApiManagement/service/$Script:apimName/apis/$apiId/operations/$apiOperationId/policies/policy?api-version=2021-08-01"

	# Getting token to use Invoke-RestMethod in stead of az rest command
	# az rest call gave errors on using the json containing the policy
	$accessToken = (az account get-access-token |ConvertFrom-Json).accessToken
	$headers = @{
				Accept = "application/json"
				Authorization = "Bearer $accessToken"
			  }
	
	$policy = $policy   -replace "`n","" -replace "`r","" -replace '"','\"'
	$json = '{"properties":{"value":"POLICY","format":"xml","method":"PUT"}}'
    $json=$json.Replace('POLICY',$policy)

	$result = Invoke-RestMethod -Method PUT -Headers $headers -Uri $uri -Body $json
	if($result.name -eq "policy"){
		Write-Host " - policy added to $apiOperationId"
	} else {
		Write-Host " >>> ERROR Creating Policy for $apiOperationId"
	}



}

# Add update product APIs
function AddApiToProduct{
	param(
		# API id/name
		[Parameter(Mandatory=$true)]
		[string]$apiId,
		
		# Api product id/name
		[Parameter(Mandatory=$true)]
        [string]$productId,
    
		# SubscriptionId
		[Parameter(Mandatory=$true)]
        [string]$subscriptionId
    )

	# add api to product
	#$apiToProduct = Add-AzApiManagementApiToProduct -Context $Script:apimContext -ProductId $productId -ApiId $apiId
	$result = az apim product api add --resource-group $Script:resourceGroup --service-name $Script:apimName --subscription $subscriptionId  --product-id $productId --api-id $apiId
	Write-Host(" - API '$apiId' added to product '$productId'")
	
}

Export-ModuleMember -Function "Init"
Export-ModuleMember -Function "ImportSwagger"