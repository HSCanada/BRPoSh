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


## update USER_ID and branch

# $cmd = @"
# SELECT        c.ShipTo AS bx_shipto, c.bx_group_id AS GROUP_ID, 407 AS USER_ID 
# FROM            BRS_Customer AS c INNER JOIN
#                         BRS_FSC_Rollup AS f ON c.TerritoryCd = f.TerritoryCd
# WHERE        (c.bx_group_id <> '') AND (f.Branch LIKE 'MNTRL%') AND (c.bx_install_date >= '20201201')
# "@

$DataRows = Invoke-MSSQL -Server $bx_server -database $bx_database -SQLCommand $cmd -ConvertFromDataRow:$false

write-output $DataRows 
