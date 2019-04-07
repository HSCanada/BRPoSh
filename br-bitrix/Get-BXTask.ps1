Import-Module -Name .\InvokeSQL.psm1 

$cmd = "SELECT * FROM nes.bx_task_load ORDER BY GROUP_ID, bx_task_id_org_seq"

$DataRows = Invoke-MSSQL -Server $env:bx_server -database $env:bx_database -SQLCommand $cmd -ConvertFromDataRow:$false

write-output $DataRows 

