param(
    [parameter(
        Mandatory         = $true,
        ValueFromPipeline = $true)]
    $pipelineInput
)

Import-Module -Force -Name .\InvokeSQL.psm1 
<#
# return new group for post processing
$output = @{
    BX_SHIPTO = $pipelineInput.bx_shipto
    BX_GROUP_ID = $group_id
    BX_SET_DATE = $pipelineInput.PROJECT_DATE_START
}
#>


$cmd = "EXEC [nes].[bx_group_update_proc] @Shipto = {0}, @GroupId = {1}, @SetDate = {2} -f $pipeline.BX_SHIPTO, $pipeline.BX_GROUP_ID, pipeline.BX_SET_DATE 


$DataRows = Invoke-MSSQL -Server $env:bx_server -database $env:bx_database -SQLCommand $cmd -ConvertFromDataRow:$false

