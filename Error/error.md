Starting: Run deployment script
==============================================================================
Task         : Azure CLI
Description  : Run Azure CLI commands against an Azure subscription in a PowerShell Core/Shell script when running on Linux agent or PowerShell/PowerShell Core/Batch script when running on Windows agent.
Version      : 2.259.1
Author       : Microsoft Corporation
Help         : https://docs.microsoft.com/azure/devops/pipelines/tasks/deploy/azure-cli
==============================================================================
C:\Windows\system32\cmd.exe /D /S /C ""C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd" --version"
WARNING: You have 2 update(s) available. Consider updating your CLI installation with 'az upgrade'
azure-cli                         2.70.0 *

core                              2.70.0 *
telemetry                          1.1.0

Extensions:
azure-devops                      0.26.0

Dependencies:
msal                            1.31.2b1
azure-mgmt-resource               23.1.1

Python location 'C:\Program Files\Microsoft SDKs\Azure\CLI2\python.exe'
Config directory 'C:\Windows\system32\config\systemprofile\.azure'
Extensions directory 'C:\Windows\system32\config\systemprofile\.azure\cliextensions'

Python (Windows) 3.12.8 (tags/v3.12.8:2dc476b, Dec  3 2024, 19:30:04) [MSC v.1942 64 bit (AMD64)]

Legal docs and information: aka.ms/AzureCliLegal


Setting AZURE_CONFIG_DIR env variable to: F:\yamlagent\dev-ag1\_work\_temp\.azclitask
Setting active cloud to: AzureCloud
C:\Windows\system32\cmd.exe /D /S /C ""C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd" cloud set -n AzureCloud"
C:\Windows\system32\cmd.exe /D /S /C ""C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd" login --service-principal -u *** "--password=***" --tenant d7790549-8c35-40ea-ad75-954ac3e86be8 --allow-no-subscriptions"
[
  {
    "cloudName": "AzureCloud",
    "homeTenantId": "d7790549-8c35-40ea-ad75-954ac3e86be8",
    "id": "fce5effc-b838-4c00-9b37-38fd1465e108",
    "isDefault": true,
    "managedByTenants": [],
    "name": "KPN B2B Integrations DEV",
    "state": "Enabled",
    "tenantId": "d7790549-8c35-40ea-ad75-954ac3e86be8",
    "user": {
      "name": "***",
      "type": "servicePrincipal"
    }
  }
]
C:\Windows\system32\cmd.exe /D /S /C ""C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd" account set --subscription fce5effc-b838-4c00-9b37-38fd1465e108"
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Unrestricted -Command ". 'F:\yamlagent\dev-ag1\_work\_temp\azureclitaskscript1753282473416.ps1'"

BRANCH: refs/heads/DEV
######################################################################################
SQL Deployment: 
BASEPATH: 'F:\yamlagent\dev-ag1\_work\20\drop\Deployment\SQLDeployment'
ENVIRONMENT: 'dev'

}
APi connections updated
======================================================================================
Creating ZIP file
======================================================================================
Deploy ZIP file
WARNING: Getting scm site credentials for zip deployment
WARNING: Starting zip deployment. This operation can take a while to complete ...
WARNING: Deployment endpoint responded with status code 202
{
  "active": true,
  "author": "N/A",
  "author_email": "N/A",
  "complete": true,
  "deployer": "ZipDeploy",
  "end_time": "2025-07-23T14:55:20.640954Z",
  "id": "fcefec8925e94f41a6db7a499a2563a0",
  "is_readonly": true,
  "is_temp": false,
  "last_success_end_time": "2025-07-23T14:55:20.640954Z",
  "log_url": "https://dev-api-ticket-la.scm.kai-dev-shared-ase.appserviceenvironment.net/api/deployments/latest/log",
  "message": "Created via a push deployment",
  "progress": "",
  "provisioningState": "Succeeded",
  "received_time": "2025-07-23T14:55:19.3128Z",
  "site_name": "dev-api-ticket-la",
  "start_time": "2025-07-23T14:55:19.3909336Z",
  "status": 4,
  "status_text": "",
  "url": "https://dev-api-ticket-la.scm.kai-dev-shared-ase.appserviceenvironment.net/api/deployments/latest"
}
Finished workflow artifacts deployment for dev-api-ticket-la in 0 : 24

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
ERROR: Not Found({"error":{"code":"WorkflowNotFound","message":"The workflow 'sms-post-kpnsms-wf' could not be found."}})
 >>> Unable to retrieve logic app trigger callback url
Finished API deployment for sms-kpn-rest-api.json in 0 : 22

======================================================================================


##[error]Script failed with exit code: 1
C:\Windows\system32\cmd.exe /D /S /C ""C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd" account clear"
Finishing: Run deployment script