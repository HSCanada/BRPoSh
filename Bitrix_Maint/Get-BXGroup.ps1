
Import-Module -Force -Name .\InvokeSQL.psm1 

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

$cmd = "SELECT * FROM nes.bx_group_load"
#$cmd = "SELECT * FROM nes.bx_group_load where bx_shipto in (3966556, 1661316, 1670574, 1667252, 3933776, 3930089)"
#$cmd = "SELECT * FROM nes.bx_group_load where bx_shipto in (2247344)"

$DataRows = Invoke-MSSQL -Server $bx_server -database $bx_database -SQLCommand $cmd -ConvertFromDataRow:$false

write-output $DataRows 

