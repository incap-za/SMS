# Introduction 
This repo is for the azure integration based on Standard Logic Apps.

The local repository should be in c:\src\repositories\kai-main

# Structure
Project Specific files are stored in the Projects folder with its subfolders:
- Logic Apps are stored in the Project\LogicApps folder. 
- Swagger files for the API specification is stored in the Project\API's folder.  
- SQL files for the **configuration** of the database are stored in the Projects/SQL folder.
- ServiceNow scripts are stored into the ServiceNowScripts folder

All tools necessary for deployment are stored in the *Deployment* folder and its subfolders.  

Scripts necessary for deployment of a story are stored in the *DeploymentScripts* folder.  

*See the readme in the mentioned folder for more details.*

# Pipeline configuration
The main pipeline **B2B-Main ASE** is configured in the main-pipeline.yml file. This pipeline retrieveds the PAT token from keyvault, use this to connect to the devops environment and collect the necessary files to start the deployment to the different environments. For the environment the powershell is extecuted.  
To deploy workflows the **B2B-Workflow ASE** pipeline is started via the powershell file. This will start another powershell to deploy *ALL*  artifacts for the Logic App, so all workflows, maps, connections etc... The specification of this pipeline is in the workflow-pipeline.yaml  
To deploy AppSettings the **B2B-AppSettings ASE** pipeline is started via the powershell file. This will start the correct powershell file to deploy the appsettings. The specification of this pipeline is in the appsettings-pipeline.yaml  

# Deployment
Deployment of the Logic App and its artifacts can be done via a powershell in the DeploymentsScripts\202x folder. A sample powershell can be found in this folder.    
As the workflows and maps are deployed via a pipeline, the files must be pushed to the repo, also before running the script manual. To avoid the main pipeline to be triggered, end the commit message with **[skip ci]**  

The main pipeline will deploy to DEV, ACC and after merge to PRD. For both ACC and PRD an approval is necessary to continue the deployment.  
To start the sub-pipelines for workflows and appsettings access to Azure Devops is necessary. For manual deployment the Windows login is used. For executing via the main pipeline a PAT token is used. When authorization errors occur, the PAt token needs to be renewed. It is stored in the DEV keyvault as ad-pat-token. To get a new PAt token, login as *srv_azrint_do_dev* in Azure Devops, select user settings and personal access token. Renew the token and store it in de DEV keyvault.

# Build and Test
Development of workflows is done via Microsoft Visual Studio Code, see the [installation instructions](https://confluence.kpn.org/pages/resumedraft.action?draftId=277652849&draftShareId=645a1fe2-da7e-430e-afb9-5eed391057d3&)  
Some more details how to work with Logic Apps and Workflows can be found at [Working with Logic Apps and Workflows](https://confluence.kpn.org/display/SNIO/Working+with+Logic+apps+and+Workflows)  
TODO: Describe and show how to build your code and run the tests. 

# .gitignore file
During local development and testing via VsCode some files and folders are created in the local repository on the developers machine. These files should not be synced towards the central repository. To prevent this, they are/must be added to the gitIgnore.  These files can be recognized in the Source Control list because they are greyed out.

