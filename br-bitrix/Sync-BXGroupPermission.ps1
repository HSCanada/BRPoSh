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
        $cmd = "EXEC [nes].[bx_group_update_proc] @Shipto = {0}, @nMode = 1" -f $rec.BX_SHIPTO
#        $cmd
        $DataRows = Invoke-MSSQL -Server $env:bx_server -database $env:bx_database -SQLCommand $cmd -ConvertFromDataRow:$false
    }
}
