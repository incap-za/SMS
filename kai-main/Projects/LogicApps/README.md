# Introduction
This folder contains the Standard Logic Apps, one folder per Logic App
The name of the folder will not contain the kai-loc part of the final Logic App name after deployment.

For the different *type* of Logic Apps there will be a seperate resourcegroup, like a kai-loc-ticket-rg an kai-loc-cmdb-rg. Each will have its specific AppInsights.  
The _sample-la folder will contain all default artifacts, so to create a new Logic App, the most easy way is to make a copy of the folder. The specification of the resourcegroup, app serviceplan etc.. will be in the la-config.json file.

Deployment of the Logic App and its artifacts can be done via a powershell in the Deployments\ManualScripts\202x folder. A sample powershell can be found in the ManualScripts folder.

# Structure
As mentioned each Logic App will have its own folder containing the necessary artifacts.  
## Default files
For each Logic App some default files are available:
- The specification of the resourcegroup, app serviceplan etc.. will be in the la-config.json file.  
- The appsettings.json contains the application settings that can be used in the workflows or connections of the Logic App  
- The connections.json file contains the connections the Logic App can use. 
- The parameters.json contains the parameters that can be used by all logic apps.

In the sample folder these files will contain all possible settings and should be cleaned to use only the settings necessary for the new logic app.


## Workflows
Each workflow in a Logic app has its own folder, according to our naming convention, the name will end with *-wf*. The folder contains a **workflow.json**. To use environment specific values it is possible to add a *wfparameter* section in the begin of the file, see the sample workflow.  
To use the wf-parameter in the workflow, use the *{{parametername}}* notation.  
During deployment these values will be replaced according the parameter specification.

## Maps
All Maps for the Logic App should be placed in the *Artifacts/Maps* folder.  
All Liquid maps should be based on the agreed template which can be found in the Artifacts/Maps folder of the sample logic app.

## Schemas
Schemas can be placed in the *Artifacts/Schemas* folder
