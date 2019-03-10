param(
    [parameter(
        Mandatory         = $true,
        ValueFromPipeline = $true)]
    $pipelineInput
)

Import-Module -Force -Name .\InvokeSQL.psm1 

<#
# return new group for post processing
$output = @{ BX_SHIPTO = 0; BX_GROUP_ID = 0; BX_SET_DATE = '2019-01-01'}
}
#>

$pipelineInput.Length

$cmd = "EXEC [nes].[bx_group_update_proc] @Shipto = {0}, @GroupId = {1}, @SetDate = {2}" -f $pipelineInput.BX_SHIPTO, $pipelineInput.BX_GROUP_ID, $pipelineInput.BX_SET_DATE 

$cmd

#$DataRows = Invoke-MSSQL -Server $env:bx_server -database $env:bx_database -SQLCommand $cmd -ConvertFromDataRow:$false

