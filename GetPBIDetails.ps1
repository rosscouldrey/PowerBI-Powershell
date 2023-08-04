#set variables
$outputPath = ".\PowerBIDetails\"
$workspacesFile = "workspaces.csv"
$reportsFile = "reports.csv"
$datasetFile = "datasets.csv"

$workspaceFilePath = $outputPath + $workspacesFile
$reportsFilePath = $outputPath + $reportsFile
$datasetFilePath = $outputPath + $datasetFile

#containers for results
$Reports = @()
$Datasets = @()

#login to powerbi with user account 
Connect-PowerBIServiceAccount

# connect-AzAccount

# # Log in to powerbi using service principal secret stored in key vault
# $myKVname = "<yourkeyvaultname>"
# $secretname = "<yoursecretname>"
# $appid = "<yourAppID>"
# $tenant = "<YourTenantID>"
# $secret = Get-AzKeyVaultSecret -VaultName $myKVname -Name $secretname
# $secretvalue = $secret.SecretValueText
# $secpasswd = ConvertTo-SecureString $secretvalue -AsPlainText -Force
# $mycreds = New-Object System.Management.Automation.PSCredential ($appid, $secpasswd)

# # #connect to powerbi
# Connect-PowerBIServiceAccount -ServicePrincipal -Credential $mycreds -TenantId $tenant

#get workspaces
$workspaces = Get-PowerBIWorkspace -Scope Organization -All

#write workspace file
$workspaces 
    | Select-Object -Property Id, Name, Type, IsReadOnly, IsOnDedicatedCapacity, CapacityId, IsOrphaned, IsOnPremiumCapacity, IsOr 
    #| Format-Table -Property Id, Name, Type, IsReadOnly, IsOnDedicatedCapacity, CapacityId, IsOrphaned, IsOnPremiumCapacity, IsOr
    | Export-Csv -Path $workspaceFilePath -NoTypeInformation

# use a counter to introduce a delay to avoid throttling
$counter = 0

foreach ($ws in $workspaces){
    #increment counter
    $counter++

    #assign workspace ID
    $workspaceId = $ws.Id

    #introduce delay to avoid throttling
    if ($counter % 10 -eq 0){
        write-output "sleeping for 2 seconds to avoid throttling"
        start-Sleep -Seconds 2
    }
   
    #get reports for each workspace
    $wsReports = Get-PowerBIReport -Scope Organization -WorkspaceId $workspaceId

    #Loop through all reports in each workspace
    foreach ($rpt in $wsReports){
        #store report details in custom object
        $Reports += [PSCustomObject] @{
            "workspace_ID" = $workspaceId 
            "report" = $rpt.Name
            "report_ID" = $rpt.Id
            "webUrl" = $rpt.WebUrl
            "embedUrl" = $rpt.EmbedUrl
            "Dataset_ID" = $rpt.DatasetId        
        } #end PsCustomObject

    }#end foreach report

    #get datasets for each workspace
    $wsDatasets = Get-PowerBIDataset -Scope Organization -WorkspaceId $workspaceId

    #loop through all datasets in each workspace
    foreach ($ds in $wsDatasets){

        $datasets += [PSCustomObject]@{
            "DatasetID" = $ds.Id
            "DatasetName" = $ds.Name
            "ConfiguredBy" = $ds.ConfiguredBy
            "DefaultRetentionPolicy" = $ds.DefaultRetentionPolicy
            "AddRowsApiEnabled" = $ds.AddRowsApiEnabled
            "Tables" = $ds.Tables
            "WebUrl" = $ds.WebUrl
            "Relationships" = $ds.Relationships
            "Datasources" = $ds.Datasources
            "DefaultMode" = $ds.DefaultMode
            "IsRefreshable" = $ds.IsRefreshable
            "IsEffectiveIdentityRequired" = $ds.IsEffectiveIdentityRequired
            "IsEffectiveIdentityRolesRequired" = $ds.IsEffectiveIdentityRolesRequired
            "IsOnPremGatewayRequired" = $ds.IsOnPremGatewayRequired
            "TargetStorageMode" = $ds.TargetStorageMode
        }#end pscustomobject
    }#end foreach dataset
}#end foreach workspace

##########################
# Write results to files
##########################

#write reports file
$Reports
    | Select-Object -Property workspace_ID, report, report_ID, WebUrl, EmbedUrl, Dataset_ID
    | Export-Csv -Path $reportsFilePath -NoTypeInformation

#write datasets file
$datasets
    | Select-Object -Property DatasetID, DatasetName, ConfiguredBy, DefaultRetentionPolicy, AddRowsApiEnabled, Tables, WebUrl, Relationships, Datasources, DefaultMode,IsRefreshable, IsEffectiveIdentityRequired, IsEffectiveIdentityRolesRequired, IsOnPremGatewayRequired, TargetStorageMode
    | Export-Csv -Path $datasetFilePath -NoTypeInformation
