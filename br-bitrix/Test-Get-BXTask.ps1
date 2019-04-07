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
		$url_addtask = $url_base + "task.item.add/"

		$url_checklistadd = $url_base + "task.checklistitem.add/"
		$url_gettasklist = $url_base + "task.item.list/"
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
			$params_addtask = "T[TITLE]=This is my title&T[DESCRIPTION]=This is my description&T[RESPONSIBLE_ID]=1&T[GROUP_ID]=383"



            


#			$res = Invoke-RestMethod -Method 'Post' -Uri $url_gettasklist -Body $params_gettasklist
#			$res = Invoke-RestMethod -Method 'Post' -Uri $url_gettasklist -Body "[{GROUP_ID : 'desc'}]"
#            $res.result
#
#			$res = Invoke-RestMethod -Method 'Post' -Uri $url_checklistadd -Body (convertto-json @{param=@(@{TASKID=1842},@{TITLE = 'checklist'})})
			$rget = Invoke-RestMethod -Method 'Post' -Uri $url_gettask -Body @{ID = 140}
#			$rget = Invoke-RestMethod -Method 'Post' -Uri $url_gettask -Body $params_gettask 
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


