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
        $cmd = "EXEC [nes].[bx_group_update_proc] @Shipto = {0}, @GroupId = {1}, @nMode = 0, @SetDate ='{2:yyyyMMdd}', @InstallDate ='{3:yyyyMMdd}', @bx_cps_code = '{4}', @bx_ess_code = '{5}', @bx_dts_code = '{6}', @bx_fsc_code = '{7}' " -f $rec.BX_SHIPTO, $rec.BX_GROUP_ID, $rec.PROJECT_DATE_START, $rec.PROJECT_DATE_FINISH, $rec.bx_cps_code, $rec.bx_ess_code, $rec.bx_dts_code, $rec.bx_fsc_code
        # $cmd

        $DataRows = Invoke-MSSQL -Server $env:bx_server -database $env:bx_database -SQLCommand $cmd -ConvertFromDataRow:$false
    }
}
