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
#$CMD = @"
#SELECT        C.SHIPTO AS BX_SHIPTO, C.BX_GROUP_ID AS GROUP_ID, 409 AS USER_ID 
#FROM            BRS_CUSTOMER AS C INNER JOIN
#                        BRS_FSC_ROLLUP AS F ON C.TERRITORYCD = F.TERRITORYCD
#WHERE        (C.BX_GROUP_ID <> '') AND (F.BRANCH LIKE 'TORNT%') AND (C.BX_INSTALL_DATE >= '20210101')
#"@

$DataRows = Invoke-MSSQL -Server $bx_server -database $bx_database -SQLCommand $cmd -ConvertFromDataRow:$false

write-output $DataRows 
