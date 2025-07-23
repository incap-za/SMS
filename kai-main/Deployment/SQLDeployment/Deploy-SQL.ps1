#
# Deploy-SQL.ps1
#
param(
  [ValidateSet("dev", "acc", "prd")]
  [Parameter(Mandatory = $true)]
  [string]$Environment,

  [Parameter(Mandatory = $false)]
  [string]$SqlScriptPath,

  [Parameter(Mandatory = $false)]
  [string]$SqlQuery,

  [Parameter(Mandatory = $false)]
  [string]$Database
)

# stop execution as encounter any exception
$ErrorActionPreference = "Stop"
#SilentlyContinue

#========================================================================================================
# Add modules
#========================================================================================================

#========================================================================================================
# setting global variables
Write-Host("######################################################################################")
$startDate =(Get-Date)
Write-Host ("SQL Deployment: ")
$Global:BASEPATH = $PSScriptRoot
Write-Host("BASEPATH: '$Global:BASEPATH'")
$Global:ENVIRONMENT = $Environment
Write-Host("ENVIRONMENT: '$Global:ENVIRONMENT'")

# get environment configuration settings
$envConfigurationJson = "$Global:BASEPATH\Config\$Global:ENVIRONMENT.json"
$Global:CONFIGURATION = Get-Content $envConfigurationJson | Out-String | ConvertFrom-Json
$Database = $Database.ToUpper()
Switch($Database )
{
  "DATAHUB-GREEN" {
    $ServerInstance = $Global:CONFIGURATION.datahubGreen.server
    $Database = $Global:CONFIGURATION.datahubGreen.database
    $Username = $Global:CONFIGURATION.datahubGreen.userName
    $Password = $Global:CONFIGURATION.datahubGreen.password
  }
  "DATAHUB-RED" {
    $ServerInstance = $Global:CONFIGURATION.dataHubRed.server
    $Database = $Global:CONFIGURATION.dataHubRed.database
    $Username = $Global:CONFIGURATION.dataHubRed.userName
    $Password = $Global:CONFIGURATION.dataHubRed.password
  }
  default {
    $ServerInstance = $Global:CONFIGURATION.sqlConnection.server
    $Database = $Global:CONFIGURATION.sqlConnection.database
    $Username = $Global:CONFIGURATION.sqlConnection.userName
    $Password = $Global:CONFIGURATION.sqlConnection.password
  }
}
Write-Host "Database: $Database"
#get Keyvault entry
$Keyvault = Get-AzKeyVaultSecret -VaultName "kai-$Global:ENVIRONMENT-shared-kv" -Name $Password -AsPlainText
#check required parameter 
try {
  if (($SqlScriptPath -eq $null -or $SqlScriptPath -eq '') -and ($SqlQuery -eq $null -or $SqlQuery -eq ''))
  {
    throw "SqlScriptPath or SqlQuery is Null or Empty. Atleast one param must be specified."
  }
  elseif ($SqlScriptPath) {

    Write-Host "Running Script : " $SqlScriptPath
    Invoke-Sqlcmd -InputFile $SqlScriptPath -ServerInstance $ServerInstance -Database $Database -UserName $Username -Password $Keyvault -QueryTimeout 36000 -Verbose -ErrorAction Stop
    write-host "##[section] Script executed Successfully"
    }
  elseif ($SqlQuery) {

    Write-Host "Running Query : " $SqlQuery

    Invoke-Sqlcmd -Query $SqlQuery -ServerInstance $ServerInstance -Database $Database -UserName $Username -Password $Keyvault -QueryTimeout 36000 -Verbose -ErrorAction Stop
    write-host "##[section] Query executed Successfully"
    }
}
catch
{
  if ($_.Exception.Message.Contains('There is already an object') -or $_.Exception.Message.Contains('must be unique') -or $_.Exception.Message.Contains('duplicate key') -or $_.Exception.Message.Contains('already exists'))
  {

    Write-Host "##[warning] Exception type: $($_.Exception.GetType().FullName)"
    Write-Host "##[warning] Exception message: $($_.Exception.Message)"
    $ErrorActionPreference = 'Continue'

  }
  else
  {

    throw

  }
}

$endDate =(Get-Date)
$duration=$endDate-$startDate
$minutes=$duration.minutes
$seconds=$duration.Seconds
Write-Host "Finished SQL deployment for $SqlScriptPath $SqlQuery in $minutes : $seconds" -ForegroundColor Green

Write-Host ""
Write-Host("======================================================================================")