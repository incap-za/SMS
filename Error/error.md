======================================================================================
######################################################################################
BASEPATH: 	 'F:\yamlagent\dev-ag1\_work\20\drop\Deployment\APIManagement'
ENVIRONMENT: 'dev'
SWAGGER: '	 'F:\yamlagent\dev-ag1\_work\20\drop\Projects\APIs\sms-kpn-rest-api.json'
Calling API module Init ...
Init Logic App Api ...
Calling API module ImportSwagger for API Id 'sms-kpn-rest-api' ...
======================================================================================
 - Importing swagger file to Azure APIM
 - Swagger file imported to API: sms-kpn-rest-api
 - Update Host details to https://b2bdev-connect.kpn.org
--------------------------------------------------
 - Deploying operation post-send
 - Creating Backend to Logic App Workflow ...
 - API backend 'bla-sms-kpn-rest-api-post-send' created
 - calling UpdateOperationPolicy ...
 - Named Value 'bla_sms-kpn-rest-api_post-send_key' created
 - policy added to post-send
--------------------------------------------------
 - calling AddApiToProduct ...
 - Setting Api to Product basicauthproduct ...
ERROR: (ValidationError) One or more fields contain incorrect values:
Code: ValidationError
Message: One or more fields contain incorrect values:
Exception Details:	(ValidationError) API cannot be added to more than one open products.
	Code: ValidationError
	Message: API cannot be added to more than one open products.
	Target: aid
 - API 'sms-kpn-rest-api' added to product 'basicauthproduct'
