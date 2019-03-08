Import-Module -Force -Name .\InvokeSQL.psm1 

$cmd = "SELECT * FROM nes.bx_group_load"

$DataRows = Invoke-MSSQL -Server $env:bx_server -database $env:bx_database -SQLCommand $cmd -ConvertFromDataRow:$false

write-output $DataRows 

