<#
Param(
        [Parameter(
                Mandatory=$True,
                ValueFromPipeline=$True) ]

        $pipelineInput
)
#>
 
        Begin {
		$url_base = $env:bx_webhook_url
		$url_gettask = $url_base + "task.item.getdata/"
		$url_gettaskchecklist = $url_base + "task.checklistitem.getlist/"
		$url_gettasklist = $url_base + "task.item.list/"
        }


        PROCESS {

#                ForEach ($rec in $pipelineInput) {

<#
			# get task list 
			$params_gettasklist = @{
                ORDER = @{ID = 'ASC'}
                FILTER = @{GROUP_ID  = 55}
			}
#>

			# get task data 
			$params_gettask = @{
			    ID = 140
			}


#			$res = Invoke-RestMethod -Method 'Post' -Uri $url_gettasklist -Body $params_gettasklist
#			$res = Invoke-RestMethod -Method 'Post' -Uri $url_gettaskchecklist -Body $params_gettask
			$res = Invoke-RestMethod -Method 'Post' -Uri $url_gettask -Body $params_gettask

<#
			# return new group for post processing
                [PSCustomObject]@{
			    BX_SHIPTO = $rec.bx_shipto
			    BX_GROUP_ID = $group_id
			    BX_SET_DATE = $rec.PROJECT_DATE_START
                }
#>


               
        }


