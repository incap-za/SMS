# Introduction
On this place the SQL scripts to create tables and stored procedures will be placed.  
SQL scripts to add data for provisioning of customers will be placed in the DeploymentScripts folder  

# Folder Structure
For the different databases there is a subfolder, containing again subfolder for the different scripts for tables, stored procedures etc...:  
- kai-db:        for the kai database 
- sn-datahub-db: for the datahub database

Beside that there are two generic folders:
- _Azure-misc:  Containing generic queries for azure integration specific queries and data generation
- _Generic:     Containing sql scripts for database management

# Schema naming
Configuration tables will be placed in the **kai** schema.  
Tables for specific integrations will be placed in a specific schema for that integration.  
Tables used by multiple integrations will be placed in a shared schema.