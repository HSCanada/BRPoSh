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
       
        # escape single quote so sql proc works
        $descr_scrub = $rec.BX_DESCRIPTION_NEW
        if($descr_scrub.length -gt 0) {
            $descr_scrub = $descr_scrub.replace("'", "''")
        }

        $cmd = "EXEC [nes].[bx_task_template_update_proc] @bx_task_id = {0}, @bx_title = '{1}', @bx_description = '{2}', @bx_checklist = '{3}'" -f $rec.BX_TASK_ID, $rec.BX_TITLE_NEW, $descr_scrub, $rec.BX_CHECKLIST_NEW
#        $cmd
        $DataRows = Invoke-MSSQL -Server $bx_server -database $bx_database -SQLCommand $cmd -ConvertFromDataRow:$false
    }
}
