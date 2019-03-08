Import-Module -Force -Name .\InvokeSQL.psm1 


$cmd = "SELECT * FROM nes.bx_group_load"

$cmd = "EXEC [nes].[bx_group_update_proc] @Shipto = 0, @GroupId = 2, @SetDate = '2019-03-07'"


$DataRows = Invoke-MSSQL -Server $env:bx_server -database $env:bx_database -SQLCommand $cmd -ConvertFromDataRow:$false

write-output $DataRows 

#$DataRows | Select-object name,database_id
