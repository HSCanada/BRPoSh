Param(
    [Parameter( Mandatory=$True, ValueFromPipeline=$True) ]
    $pipelineInput
)
# add $null pipline handler

Begin {
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

}
Process {
    ForEach ($rec in $pipelineInput) {
        $cmd = "EXEC [nes].[bx_group_update_proc] @Shipto = {0}, @nMode = 1" -f $rec.BX_SHIPTO
#        $cmd
        $DataRows = Invoke-MSSQL -Server $bx_server -database $bx_database -SQLCommand $cmd -ConvertFromDataRow:$false
    }
}
