
# Connect to Power BI
Connect-PowerBIServiceAccount

# Get all gateways
$gateways = Invoke-PowerBIRestMethod -Method Get -Url "https://api.powerbi.com/v1.0/myorg/gateways" | ConvertFrom-Json



$gateways | Select-Object *, @{Name = "TenantID"; Expression = {$_.id}} -ExcludeProperty id, value | Select-Object -Property TenantID, @{Name = "clusterID"; Expression = {$_.value.id}}, @{Name = "gatewayID"; Expression = {$_.value.gatewayId}}, @{Name = "gatewayName"; Expression = {$_.value.name}}, @{Name = "gatewayType"; Expression = {$_.value.gatewayType}}, @{Name = "gatewayVersion"; Expression = {$_.value.gatewayVersion}}, @{Name = "gatewayStatus"; Expression = {$_.value.gatewayStatus}}, @{Name = "gatewayDatasourceType"; Expression = {$_.value.datasourceType}}, @{Name = "gatewayDatasourceName"; Expression = {$_.value.datasourceName}}, @{Name = "gatewayDatasourceConnectionString"; Expression = {$_.value.connectionString}}, @{Name = "gatewayDatasourceCredentialType"; Expression = {$_.value.credentialType}}, @{Name = "gatewayDatasourceCredentialUsername"; Expression = {$_.value.credentialUsername}}, @{Name = "gatewayDatasourceCredentialEncrypted"; Expression = {$_.value.credentialEncrypted}} | Format-Table

