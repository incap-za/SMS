# Introduction

This folder will contain the PowerShell and SQL scripts necessary to deploy a story.  
There will be one folder for each story, grouped in a subfolder by year for overview.  

# Naming conventions

The folder for the story will have a naming convention as follows:
- Start with the storynumber (KAI-12345 or BUG-12345)
- Followed with the integration name
- Ended with a short description

**Example**: KAI-12345-CUSTOMERNAME-Initial-inbound-email

The name of the powershell can be simple like 'deploy.ps1' as there will be just one for each story.  
Also the name of the SQL can be simple, however dependend of the story multiple SQL scripts can be executed.