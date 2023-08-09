########################################
# This script will get the following details from all workspaces in a Power BI tenant:
#   - Workspaces
#   - Reports
#   - Dashboards
#   - Datasets
#
##########################################

#set variables
$outputPath = ".\PowerBIDetails\"
$workspacesFile = "workspaces.csv"
$reportsFile = "reports.csv"
$datasetFile = "datasets.csv"
$dashboardFile = "dashboards.csv"
$dataflowFile = "dataflows.csv"

$workspaceFilePath = $outputPath + $workspacesFile
$reportsFilePath = $outputPath + $reportsFile
$datasetFilePath = $outputPath + $datasetFile
$dashboardFilePath = $outputPath + $dashboardFile
$dataflowFilePath = $outputPath + $dataflowFile

#containers for results
$Reports = @()
$Datasets = @()
$dashboards = @()
$dataflows = @()

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

# Get user input for Admin flag
$Admin = Read-Host -Prompt "Would you like to run this script as a Power BI Admin? (Y/N)"

#if admin then set scope to Organization, else set it to Individual
if ($Admin -eq "Y"){
    $scope = "Organization"
    Write-Host "`r`nRunning scripts using scope 'Organization'.  This will return all workspaces in the tenant and may return errors if you are not using an account with Admin privileges. `r`n"
}
else{
    $scope = "Individual"
    Write-Host "`r`nRunning scripts using scope 'Individual'.  This will return all workspaces that you have access to. `r`n"
}

#get workspaces
$workspaces = Get-PowerBIWorkspace -Scope $scope -All

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
    $wsReports = Get-PowerBIReport -Scope $scope -WorkspaceId $workspaceId

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

    #get dashboards for each workspace
    $wsDashboards = Get-PowerBIDashboard -Scope $scope -WorkspaceId $workspaceId

    #Loop through all reports in each workspace
    foreach ($dash in $wsDashboards){
        #store report details in custom object
        $dashboards += [PSCustomObject] @{
            "workspace_ID" = $workspaceId 
            "Dashboard" = $dash.Name
            "Dashboard_ID" = $dash.Id
            "embedUrl" = $dash.EmbedUrl      
        } #end PsCustomObject

    }#end foreach dashboard

    #get datasets for each workspace
    $wsDatasets = Get-PowerBIDataset -Scope $scope -WorkspaceId $workspaceId

    #loop through all datasets in each workspace
    foreach ($ds in $wsDatasets){

        $datasets += [PSCustomObject]@{
            "workspace_ID" = $workspaceId
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

 #get dataflows for each workspace
 $wsDataFlows = Get-PowerBIDataset -Scope $scope -WorkspaceId $workspaceId

 #loop through all datasets in each workspace
 foreach ($df in $wsDataFlows){

     $dataflows += [PSCustomObject]@{
        "Workspace_ID" = $workspaceId 
        "Dataflow_ID" = $df.Id
        "DataflowName" = $df.Name
        "Description"= $df.Description
        "ModelURL" = $df.ModelURL
        "ConfiguredBy" = $df.ConfiguredBy
     }#end pscustomobject
 }#end foreach dataflow

}#end foreach workspace

##########################
# Write results to files
##########################

#write reports file
$Reports
    | Select-Object -Property workspace_ID, report, report_ID, WebUrl, EmbedUrl, Dataset_ID
    | Export-Csv -Path $reportsFilePath -NoTypeInformation

#write Dashboards file
$dashboards
| Select-Object -Property workspace_ID, Dashboard, Dashboard_ID, EmbedUrl
| Export-Csv -Path $dashboardFilePath -NoTypeInformation

#write datasets file
$datasets
    | Select-Object -Property DatasetID, DatasetName, ConfiguredBy, DefaultRetentionPolicy, AddRowsApiEnabled, Tables, WebUrl, Relationships, Datasources, DefaultMode,IsRefreshable, IsEffectiveIdentityRequired, IsEffectiveIdentityRolesRequired, IsOnPremGatewayRequired, TargetStorageMode
    | Export-Csv -Path $datasetFilePath -NoTypeInformation

$dataflows
    | Select-Object -Property Workspace_ID, Dataflow_ID, DataflowName, Description, ModelURL, ConfiguredBy
    | Export-Csv -Path $dataflowFilePath -NoTypeInformation
