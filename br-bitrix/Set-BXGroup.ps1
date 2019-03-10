Param(
        [Parameter(
                Mandatory=$True,
                ValueFromPipeline=$True) ]

        $pipelineInput
)

        Begin {
 
		Import-Module -Force -Name .\InvokeSQL.psm1 

	}
	Process {
                ForEach ($rec in $pipelineInput) {
 
			$cmd = "EXEC [nes].[bx_group_update_proc] @Shipto = {0}, @GroupId = {1}, @SetDate = {2}" -f $rec.BX_SHIPTO, $rec.BX_GROUP_ID, $rec.BX_SET_DATE 

			$cmd

			#$DataRows = Invoke-MSSQL -Server $env:bx_server -database $env:bx_database -SQLCommand $cmd -ConvertFromDataRow:$false
		}
	}
