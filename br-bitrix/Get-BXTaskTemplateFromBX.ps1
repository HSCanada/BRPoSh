Param(
    [Parameter( Mandatory=$True, ValueFromPipeline=$True) ] 
    $pipelineInput
)
 

Begin {
    $url_base = $env:bx_webhook_url
#    $task_id = 2208
}

PROCESS {
            
    ForEach ($rec in $pipelineInput) {
        $task_id = $rec.bx_task_id_map
            
        # get descr
        $res = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.item.getdata/") -Body @{ID = $task_id}
        $res_descr = $res.result

        # get checklist array
        $res = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.checklistitem.getlist/") -Body @{ID = $task_id}
        $res_check = $res.result

        # compress checklist
        $check_array = @()
        ForEach ($line in $res_check) {$check_array += $line.TITLE}
        $check_line = $check_array -join '|'

        # done
        [PSCustomObject]@{
            BX_TASK_ID = $rec.bx_task_id
            BX_TITLE = $res_descr.TITLE
            BX_DESCRIPTION = $res_descr.DESCRIPTION
            BX_CHECKLIST = $check_line
        }
   }
}
