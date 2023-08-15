########################################
# This script will get Gateway details for a powerbi environment:
#
##########################################

Login-PowerBIServiceAccount

$gateways = Invoke-PowerBIRestMethod -Method Get -Url "https://api.powerbi.com/v2.0/myorg/gatewayClusters?`$expand=memberGateways" | 
        ConvertFrom-Json

if($gateways.value.length -gt 0){
    #enumerate memberGateways
    $gateways.value
        | Select-Object -Property @{Name = "clusterID"; Expression = {$_.id}}, memberGateways
        | Select-Object * -ExpandProperty memberGateways -ExcludeProperty memberGateways
}