Param(
    [Parameter( Mandatory=$True, ValueFromPipeline=$True) ]
    $pipelineInput
)
# add $null pipline handler

Begin {
 
    Import-Module -Force -Name .\InvokeSQL.psm1 
}
Process {
    ForEach ($rec in $pipelineInput) {
       
        # escape single quote so sql proc works
        $descr_scrub = $rec.BX_DESCRIPTION.replace("'", "''")

        $cmd = "EXEC [nes].[bx_task_template_update_proc] @bx_task_id = {0}, @bx_title = '{1}', @bx_description = '{2}', @bx_checklist = '{3}'" -f $rec.BX_TASK_ID, $rec.BX_TITLE, $descr_scrub, $rec.BX_CHECKLIST
#        $cmd
        $DataRows = Invoke-MSSQL -Server $env:bx_server -database $env:bx_database -SQLCommand $cmd -ConvertFromDataRow:$false
    }
}
