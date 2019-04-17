Import-Module -Force -Name .\InvokeSQL.psm1 

$cmd = "SELECT [bx_task_id], [bx_task_id_map], [bx_title],[bx_description],[bx_checklist] FROM [nes].[bx_task_template] where bx_task_id > 0"

$DataRows = Invoke-MSSQL -Server $env:bx_server -database $env:bx_database -SQLCommand $cmd -ConvertFromDataRow:$false

write-output $DataRows 

