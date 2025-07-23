# Introduction
This Deployment folder will contain all resources necessary to deploy artifacts towards the Azure environment. Either manual or via a pipeline.

# Structure

## APIManagement
The APIManagement folder contains all the artifacts to deploy an API to Azure and to connect a workflow to that API. It will also contain the policies that can be used. This because for each policy there is also specific powershell code. 

## EnvironmentSetup
The EnvironmentSetup folder contains the artifacts to deploy a resource group. Potentially this folder will also cotain artifacts to deploy other environmental artifacts.

## LogicApps
The LogicApps folder contains all the artifacts to deploy LogicApps and its artifacts to be called from the powershell as defined in the ManualScripts folder
- The DeployAppSettings powershell will deploy appsettings as defined in the appSettings.json of the Logic App
- DeployLA *to be finalized later*
- The DeployWF powershell will deploy all LogicApp artifacts as defined in the Logic App folder

## SQLDeployment
The SQLDeployment folder contains the artifacts to deploy SQL code to the B2B database.
At the moment this is only possible via the pipeline.

## TestAutomation
This folder will contain in the future all artifacts to be used for test autmation