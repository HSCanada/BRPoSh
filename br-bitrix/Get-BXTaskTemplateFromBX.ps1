Param(
    [Parameter( Mandatory=$True, ValueFromPipeline=$True) ] 
    $pipelineInput
)
 

Begin {

    if($env:BRS_MODE -eq "PROD") {
        $bx_server = $env:BRS_SQLSERVER
        $bx_database = $env:bx_database
        $bx_webhook_url = $env:bx_webhook_url
    } 
    else {
        $bx_server = $env:BRS_SQLSERVER
        $bx_database = $env:bx_database_DEV
        $bx_webhook_url = $env:bx_webhook_url_DEV
    }

    $url_base = $bx_webhook_url
#    $task_id = 2208
}

PROCESS {
            
    ForEach ($rec in $pipelineInput) {
        $task_id = $rec
#        $task_id = $rec.bx_task_id_map
            
        # get descr
        $res = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.item.getdata/") -Body @{ID = $task_id}
        $res_descr = $res.result

# test 
#        $params_updatetask = "TASKID={0}&T[DESCRIPTION]={1}" -f $task_id, $res_descr.TITLE
#        $res_update = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.item.update/") -Body ([System.Text.Encoding]::UTF8.GetBytes($params_updatetask)) 

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
            BX_TITLE = $rec.bx_title
            BX_TITLE_NEW = $res_descr.TITLE
            BX_DESCRIPTION_NEW = $res_descr.DESCRIPTION
            BX_CHECKLIST_NEW = $check_line
        }
   }
}
