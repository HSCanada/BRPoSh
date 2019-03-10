#test
#Function Test-Pipeline {
	
#[CmdletBinding()]

Param(
	[Parameter(
		Mandatory=$True,
		ValueFromPipeline=$True) ]

	$pipelineInput
)
	Begin {
	#	$pipelineInput.length
		$output = @()
	}

	PROCESS {

		ForEach ($rec in $pipelineInput) { 
			write-host $rec
			[PSCustomObject]@{
				NAME =	$rec.Name
				BX_SHIPTO = $rec.BX_shipto
			}

            	}
	}
	End {
	#	Write-Output $output
	}
#}
