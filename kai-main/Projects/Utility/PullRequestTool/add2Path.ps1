#======================================================================
# Author:      CTP
# Date:        2023 November 24
# Description: This script will add the tools folder to the path
#              if it is not in the path yet
#======================================================================

cls
if (Test-Path -path C:\src\repositories\kai-main\Projects\Utility\PullRequestTool){
    echo "Folder allready in Path"
} else {
    $env:Path +=";C:\src\repositories\kai-main\Projects\Utility\PullRequestTool"
    echo "Folder added to Path"
}