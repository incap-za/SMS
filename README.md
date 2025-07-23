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

