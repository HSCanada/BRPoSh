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

$cmd = "SELECT [bx_task_id], [bx_task_id_map], [bx_title],[bx_description],[bx_checklist] FROM [nes].[bx_task_template] where bx_task_id > 0"

$DataRows = Invoke-MSSQL -Server $bx_server -database $bx_database -SQLCommand $cmd -ConvertFromDataRow:$false

write-output $DataRows 

