#############################
#  This script must be run as an admin
#############################

#introduce counter to avoid API throttling
$counter = 0

#login to powerbi
Connect-PowerBIServiceAccount

#get workspaces
$workspaces = Get-PowerBIWorkspace -Scope Organization -All

#for each workspace issue an invoke rest API call to get unused artifacts
foreach($ws in $workspaces){

    #get workspace.id
    $wsid = $ws.Id

#get unused artifacts
$output = Invoke-PowerBIRestMethod -Method Get -Url "https://api.powerbi.com/v1.0/myorg/admin/groups/$wsid/unused"
print $output

$counter ++

}



