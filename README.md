Get the changed files for commit/PR/master

View raw log

Starting: Get the changed files for commit/PR/master
==============================================================================
Task         : Azure PowerShell
Description  : Run a PowerShell script within an Azure environment
Version      : 5.257.0
Author       : Microsoft Corporation
Help         : https://aka.ms/azurepowershelltroubleshooting
==============================================================================
AZUREPS_HOST_ENVIRONMENT: ADO/AzurePowerShell@v5_Windows_NT_kaidevdevops02-acc-ag1_B2B-Main ASE_427586__
Generating script.
========================== Starting Command Output ===========================
"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Unrestricted -Command ". 'F:\yamlagent\acc-ag1\_work\_temp\a13b2876-dc46-4b0e-9bd9-e6e50050599f.ps1'"
Import-Module -Name C:\Program Files\WindowsPowerShell\Modules\Az.Accounts\3.0.4\Az.Accounts.psd1 -Global
Update-AzConfig -CheckForUpgrade False -AppliesTo Az -Scope Process

Get-AzConfig -AppliesTo Az
Update-AzConfig -DisplayBreakingChangeWarning False -AppliesTo Az -Scope Process
Enable-AzureRmAlias -Scope Process
Clear-AzContext -Scope CurrentUser -Force -ErrorAction SilentlyContinue
Clear-AzContext -Scope Process
Clear-AzConfig -DefaultSubscriptionForLogin
Connect-AzAccount 
Name                           Value                                                                                   
----                           -----                                                                                   
Tenant                         ***                                                    
Scope                          Process                                                                                 
Environment                    AzureCloud                                                                              
Credential                     System.Management.Automation.PSCredential                                               
WarningAction                  SilentlyContinue                                                                        
ServicePrincipal               True                                                                                    



Key                          Value Applies To Scope   Help Message                                                     
---                          ----- ---------- -----   ------------                                                     
CheckForUpgrade              False Az         Process When enabled, Azure PowerShell will check for updates automati...
DisplayBreakingChangeWarning False Az         Process Controls if warning messages for breaking changes are displaye...

Environments : {[AzureChinaCloud, AzureChinaCloud], [AzureCloud, AzureCloud], [AzureUSGovernment, AzureUSGovernment]}
Context      : Microsoft.Azure.Commands.Profile.Models.Core.PSAzureContext

VERBOSE: Command [Connect-AzAccount] succeeded.
Set-AzContext 
Name                           Value                                                                                   
----                           -----                                                                                   
SubscriptionId                 fce5effc-b838-4c00-9b37-38fd1465e108                                                    




Name               : KPN B2B Integrations DEV (fce5effc-b838-4c00-9b37-38fd1465e108) - 
                     *** - ***
Subscription       : fce5effc-b838-4c00-9b37-38fd1465e108
Account            : ***
Environment        : AzureCloud
Tenant             : ***
TokenCache         : 
VersionProfile     : 
ExtendedProperties : {}



# SMS
Description:
Scope:
•	SMS API
•	Migrate the SMS API to the target ASE-design
•	Migrate from SMS-provider Vonage (https://developer.kpn.com/products/vonage-messages-api) to provider KPN (https://developer.kpn.com/products/kpn-sms-api)
•	FYI: Vonage used to be called 'Nexmo'
•	Update the confluence-page: https://confluence.kpn.org/spaces/SNIO/pages/300747186/SMS+API
•	Update the SMS API documentation
•	Create test-cases
•	BA-tests & approval will be done by our own team.

Acceptance Criteria:
•	The SMS API is migrated to the target ASE-design
•	The SMS API is connected to provider KPN (in stead of Vonage)
•	The confluence-page has been updated.
•	The SMS API documentation has been updated.
•	Test-cases are available.










The following is listed on the confluence page:

SMS API

Information will be added
API's:
•	SMS KPN Rest API
•	SMS KPN SOAP API
Only ServiceNow Black is still using the SMS KPN SOAP API
Default Sender ID: KPNB2B
SMS Provider Vonage: https://developer.kpn.com/products/vonage-sms-api

Example outbound JSON-message from SN Green to SMS KPN Rest API:

{
  "caseid" : "jjansen@ABC",
  "mobilephones" : [ "+31612345678" ],
  "operator" : "KPN",
  "smsmessage" : "Your new temporary password for the ServiceNow with validation code 01234567 is: ********** ",
  "source" : "SN"
}

