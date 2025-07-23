#======================================================================
# Author:      CTP
# Date:        2023 November 24
# Description: This script will commit & push changes to the current 
#              working branch, create the PR and if it is a QA or BA
#              PR, assign the reviewer random and move the work-item
#              to the QA/BA state.
# Input:       type: the type of PR, possible values dev, qa or ba
#              message: The message to add to the commit
#======================================================================

param(
    [ValidateSet("dev","qa","ba")]
    [Parameter(Mandatory=$true)]
    $type,
    [Parameter(Mandatory=$true)]
    $message
)
cls
if((Get-Item .).FullName -notcontains "C:\src\repositories\kai-main"){
    cd C:\src\repositories\kai-main
}
$branchName = git rev-parse --abbrev-ref HEAD # Get current branch
$storyName = $branchName -replace "feature/","" -replace "hotfix/",""
$workItemId = $storyName.Split('-')[1]       # Get story number from branchname
$userName = git config user.email             # Get username
# Get allready assigned reviewers
$fields = az boards query --wiql "SELECT [Custom.QAReviewer],[Custom.BAReviewer] FROM workitems WHERE [System.Id]=$workItemId" | ConvertFrom-Json
$QA =  $fields.fields.'Custom.QAReviewer'.uniqueName
$BA =  $fields.fields.'Custom.BAReviewer'.uniqueName

# Set source & destination branch
$source = "refs/heads/" + $branchName
switch($type){
    dev {
            $target="refs/heads/DEV"
            $title = "DEV-" + $storyName + " " + $message
            break
        }
    qa {
            $target="refs/heads/ACC"
            $title = "QA " + $storyName
            break
       }
    ba {
            $target="refs/heads/master"
            $title = "BA " + $storyName
            break
       }
}

echo "Merging branch $storyName to $target for story KAI-$workItemId"
echo "---------------------------------------------------------------"

#commit & push all changes
git add --all
echo " - Commit & push changes"
git commit -m $message
try {
    git push #origin
} catch {
    #ignore push error
}

#create PR 
echo " - Create PR: $title" # for dev, it is directly merged!!!!
$pr = az repos pr create --repository kai-main --source-branch $source --target-branch $target --title $title --work-items $workItemId --organization https://dev.azure.com/kpn/ --project "ServiceNow IO" | ConvertFrom-Json

# Do some stuff depending on type of PR
switch($type){
    dev {
            # if dev, complete it
            sleep 3
            echo " - Set auto complete DEV PR"
            $appr = az repos pr update --id $pr.pullRequestId --bypass-policy true --bypass-policy-reason "DEV auto complete"
            sleep 2
            echo " - Approving DEV PR"
            $appr = az repos pr set-vote --id $pr.pullRequestId --vote approve
            #sleep 2
            #echo " - Completing DEV PR"
            #$appr = az repos pr update --id $pr.pullRequestId --status completed # Gives error in Build
        }
    qa  {
            #if($QA=""){
            #    # assign QA reviewer
            #    $QaList=’cor.paarlberg@kpn.com’,’johan.scheepers@kpn.com’,’shweta.sing@kpn.com’,’twan.derksen@kpn.com’
            #    $QA = Get-Random $QaList
            #    while($QA -eq $userName){
            #        $QA = Get-Random $QaList
            #    }
            #    echo " - Assign QA to $QA"
            #    $action=az boards work-item update --id $workItemId --fields "QA Reviewer=$QA"
            #    $action = az repos pr reviewer add --id $workItemId --reviewers $QA
            #}
            echo " - Move story to QA"
            $action=az boards work-item update --id $workItemId --fields "state=QA"
        }
    ba  {
            #if($QB=""){
            #    # assign BA reviewer
            #    $BaList=’cor.paarlberg@kpn.com’,’johan.scheepers@kpn.com’,’shweta.sing@kpn.com’,’twan.derksen@kpn.com’,'sandesh.tombare@kpn.com','daniel.puister@kpn.com','sharnish.karamadaishanmugasundaram@kpn.com'
            #    $BA = Get-Random $BaList
            #    while($BA -eq $userName){
            #        $BA = Get-Random $QaList
            #    }
            #    echo " - Assign BA to $BA"
            #    $action=az boards work-item update --id $workItemId --fields "BA Reviewer=$BaCheck"
            #    $action = az repos pr reviewer add --id $workItemId --reviewers $BA
            #}
            echo " - Move story to BA"
            $action=az boards work-item update --id $workItemId --fields "state=BA"
        }
}
echo "---------------------------------------------------------------"
echo "Done!!!"
