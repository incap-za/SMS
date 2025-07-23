#========================================================================================================
#
# Module-Utils.psm1
#
# Contains functions for:
# - Get the parameter object value form the environment configuration file to create the correct appsetting
# - Converting wfparameters in workflow definition to an environment specific workflow.json file
#
#========================================================================================================

$global:ENVIRONMENT
#==============================================================================================
# get parameter object based on environment used to deploy the appSettings
#==============================================================================================
function Get-ParameterObjectValue{

    param(
        [Parameter(Mandatory=$true)]
        [string]$value
    )
    $PlainTextValue = $value

    $Private:envSettingsJson = $Global:CONFIGURATION
    $Private:envSettings = [Regex]::Matches($value, "(?<={{).+?(?=}})")
    foreach($EnvSetting in $EnvSettings)
    {
            $SettingProps = $EnvSetting.Value.Split('.')

            $ObjSetting = $EnvSettingsJson
            $PropValue = "";
            for($i = 0; $i -lt $SettingProps.Count; $i++)
            {
                $Property = $SettingProps[$i]
                if($i -lt ($SettingProps.Count - 1)){
                    $ObjSetting = $ObjSetting.$property
                }
                else{
                    $PropValue = $ObjSetting.$property
                }
            }

            # replace settings object with property value
            $PlainTextValue = $PlainTextValue -replace "{{$EnvSetting}}", $PropValue
    }

    # return plain text for property object value
    # replace all env and settings object with its appropriate values
    return $PlainTextValue
}

#==============================================================================================
# Convert paramters.json to add the values from the config file
#==============================================================================================
function Convert-Parameters{
    param (
        [ValidateSet("dev", "acc", "prd")]
        [Parameter(Mandatory=$true)]
        [string]$Environment,

        [Parameter(Mandatory=$true)]
        [string]$LogicAppFolder
    )
    $global:ENVIRONMENT = $Environment
    $Global:BASEPATH = $PSScriptRoot
    # get environment configuration settings
    $EnvConfigurationJson = "$Global:BASEPATH\Config\$Global:ENVIRONMENT.json" -replace ([regex]::Escape('Modules\')) ,''
    $Global:CONFIGURATION = Get-Content $EnvConfigurationJson | Out-String | ConvertFrom-Json
    Write-Host("ENV-CONFIG:  '$EnvConfigurationJson'")
    try{
        $ParameterFile = $LogicAppFolder + '\parameters.json' -replace ([regex]::Escape('/')) ,([regex]::Escape('\'))
        Write-Host "PARAMETERS: $ParameterFile"
        $Parameters = Get-Content $ParameterFile | ConvertFrom-Json
        $Parameters.psObject.Properties | ForEach-Object{
            $ParameterName = $_.Name
            $ParameterType = $_.value.type
            if($ParameterType -eq "String"){
                $ParameterValue = $_.Value.value
                if ($ParameterValue.StartsWith("{{")){
                    $ParameterValue = Get-ParameterObjectValue -value $ParameterValue
                    $_.Value.value = $ParameterValue
                }
                Write-Host " - Parameter: $ParameterName = $ParameterValue"
            } elseif($ParameterType -eq "Object"){
                Write-Host " - Parameter: $ParameterName :"
                $_.Value.value.psObject.Properties | ForEach-Object{
                    # Loop over the object properties
                    $PropertyName = $_.Name
                    $PropertyValue = $_.Value
                    if ($PropertyValue.StartsWith("{{")){
                        $PropertyValue = Get-ParameterObjectValue -value $PropertyValue
                        $_.Value = $PropertyValue
                    }
                    Write-Host "   - $PropertyName = $PropertyValue"
                }
            } else {
                Throw " >>>>> Error: Dynamic parametertype $ParameterType not Supported <<<<<"
            }
        } 
        $Json = $Parameters | ConvertTo-Json 
        Set-Content -Path $ParameterFile $Json
        Write-Host "Finished..."
    } catch {
        Write-Host $Error
        Throw ">>>> ERROR: Processing:  '$LogicAppFolder' for $global:ENVIRONMENT Failed <<<<"
    }

}

#==============================================================================================
# Convert workflow to replace the wf-parameters
#==============================================================================================
function Convert-Workflow{
    param (
        [ValidateSet("dev", "acc", "prd")]
        [Parameter(Mandatory=$true)]
        [string]$Environment,

        [Parameter(Mandatory=$true)]
        [string]$WorkflowFolder
    )
    $global:ENVIRONMENT = $Environment

    $FolderName= $WorkflowFolder.split('\')[-1]
    Write-Host("------------------------------")
    Write-Host("Processing:  '$FolderName' for $global:ENVIRONMENT")
    try{
        $WorkflowFile = $WorkflowFolder + '\workflow.json'
        Write-Host "File: $WorkflowFile"
        $ParameterHashTable = Get-TemplateParameterObject -WorkflowFile $WorkflowFile -Environment $Environment
        UpdateFile -File $WorkflowFile  -parameterHashTable $ParameterHashTable
        
        Write-Host "Finished..."
    } catch {
        Throw ">>>> ERROR: Processing:  '$FolderName' for $global:ENVIRONMENT Failed <<<<"
    }

}

#================================================================================================
# Create parameter object with its values as defined in wfparameter section of the workflow.json
#================================================================================================
function Get-TemplateParameterObject{
	param(
        [ValidateSet("dev", "acc", "prd")]
        [Parameter(Mandatory=$true)]
        [string]$Environment,
        [Parameter(Mandatory=$true)]
        [string]$WorkflowFile
	)

	# get json object from logic app arm template file
    $JSON = Get-Content $WorkflowFile | Out-String | ConvertFrom-Json

    # create hash table object to store parameter variables
    $ParameterHashTable = New-Object HashTable
    foreach($Property in $JSON.wfparameters.PSObject.Properties){
        # hashtable key
        $PropertyName = $Property.Name
        # hashtable value
        $PropertyValue = $Property.Value

		# parse default parameter values based on its type
		$Type = $PropertyValue.type.ToLowerInvariant()
        switch($Type){
            "string"
            {
                $Value=$PropertyValue.value -replace "{{env}}", $Environment
                Write-Host("Setting string type parameter: $PropertyName - Value: $Value")                
				$ParameterHashTable.Add($PropertyName, $Value)
            }
            "object"
            {
                $Value = $PropertyValue.value.$Environment
                Write-Host("Setting object type parameter: $PropertyName")
                $ParameterHashTable.Add($PropertyName, $Value)
            }
            default
            {
                Write-Host("Not supported type identified: $Type. Default value will be used during deployment for parameter: $PropertyName!")
            }
        }
    }

	return $ParameterHashTable
}

#==============================================================================================
# Create updated workflow or parameter file with the replaced (wf)parameters
#==============================================================================================
function UpdateFile{
	param(
        [Parameter(Mandatory=$true)]
        [string]$File,
        [Parameter(Mandatory=$true)]
        [object]$ParameterHashTable
	)
	# get json object from logic app arm template file
    $UpdatedFile = Get-Content $File -Raw 
    foreach($Parameter in $ParameterHashTable.keys){
        # Loop over all the action properties
        $OldValue = "{{$Parameter}}"
        $NewValue = $ParameterHashTable[$Parameter]
        Write-Host " Updating $OldValue for $NewValue"
        $UpdatedFile = $UpdatedFile.replace( $OldValue, $NewValue )
    }
    $JsonObj = $UpdatedFile | ConvertFrom-Json
    # remove wfparameters object, exists only in workflow file
    $JsonObj.PSObject.Properties.Remove('wfparameters')
    $Json = $JsonObj | ConvertTo-Json -Depth 100 
    Set-Content -Path $File $Json

}