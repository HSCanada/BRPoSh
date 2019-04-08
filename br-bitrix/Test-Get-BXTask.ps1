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


        }


        PROCESS {

#                ForEach ($rec in $pipelineInput) {


			# get task list 
			$params_gettasklist = '{O[ID]=asc&F[GROUP_ID]=367&P[]&S[]}'
			



			# get task data 
			$params_gettask = @{
			    ID = 140
			}

			# add task data 
#			$params_addtask = "T[TITLE]=This is my title&T[DESCRIPTION]=This is my description&T[RESPONSIBLE_ID]=1&T[GROUP_ID]=383"


			$res = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.item.getdescription/") -Body @{ID=3643}
#			$res = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.item.list/") -Body "O[]&F[GROUP_ID]=367&P[]"
            $res.result
			$res = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.checklistitem.getlist/") -Body @{TASKID=3643}
            $res.result#

#			$rget = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.item.update/") -Body ("ID=2875&T[DEADLINE]={0}" -F (Get-Date))
#			$rget = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.item.getdata/") -Body @{ID = 2993}
#            $rget.result#			$rget = Invoke-RestMethod -Method 'Post' -Uri $url_gettask -Body $params_gettask 

#            $rget.result
#   		$radd = Invoke-RestMethod -Method 'Post' -Uri $url_addtask -Body $params_addtask
#    		$radd = Invoke-RestMethod -Method 'Post' -Uri $url_addtask -Body $params_addtask

<#
			# return new group for post processing
                [PSCustomObject]@{
			    BX_SHIPTO = $rec.bx_shipto
			    BX_GROUP_ID = $group_id
			    BX_SET_DATE = $rec.PROJECT_DATE_START
                }
#>


               
        }


