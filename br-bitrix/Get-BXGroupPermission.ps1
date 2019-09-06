Import-Module -Name .\InvokeSQL.psm1 

if($env:BRS_MODE -eq "PROD") {
    $bx_server = $env:BRS_SQLSERVER
    $bx_database = $env:bx_database
    $bx_webhook_url = $env:bx_webhook_url
} 
else {
    $bx_server = $env:BRS_SQLSERVER
    $bx_database = $env:bx_database_DEV
    $bx_webhook_url = $env:bx_webhook_url_DEV
}

$cmd = "SELECT * FROM nes.bx_group_permission_load ORDER BY GROUP_ID, USER_ID"
# manual add
#$cmd = "SELECT ShipTo as bx_shipto, bx_group_id as GROUP_ID, 40 as USER_ID FROM BRS_Customer where bx_group_id <>'' UNION ALL SELECT ShipTo as bx_shipto, bx_group_id as GROUP_ID, 47 as USER_ID FROM BRS_Customer where bx_group_id <>''"

$DataRows = Invoke-MSSQL -Server $bx_server -database $bx_database -SQLCommand $cmd -ConvertFromDataRow:$false

write-output $DataRows 

