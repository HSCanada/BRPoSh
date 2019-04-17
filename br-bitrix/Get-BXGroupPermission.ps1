Import-Module -Name .\InvokeSQL.psm1 

$cmd = "SELECT * FROM nes.bx_group_permission_load ORDER BY GROUP_ID, USER_ID"

$DataRows = Invoke-MSSQL -Server $env:bx_server -database $env:bx_database -SQLCommand $cmd -ConvertFromDataRow:$false

write-output $DataRows 

