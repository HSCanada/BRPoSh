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
    $group_id_current = -1

    # hardcoded IDs to allow conditional autoclose invalid options
    $design_parent_id = 1836
    $design_newreno_list = (1750,1751,1752,1836)
    $design_xray_list = (1753,1754)
}

PROCESS {
            
    ForEach ($rec in $pipelineInput) {

        # reset hash at start of new group
        if ($group_id_current -ne $rec.GROUP_ID) {
            $parent_hash = $null
            $parent_hash = @{}

            $task_id_hash = $null
            $task_id_hash = @{}

            $group_id_current = $rec.GROUP_ID
        }

        $deadline = $null
        if ($rec.PRIORITY -eq 2) { $deadline = $rec.END_DATE_PLAN }

        $parent_id = $parent_hash[$rec.TAGS]

        # URL rest encoding work-around hack
        $descr_scrub = $rec.DESCRIPTION
        if($descr_scrub.length -gt 0) {
            # escape REST delimiter 
            $descr_scrub = $descr_scrub.Replace('&', '%26')

            #replace references to template path with new group path.  
            #Assume the production group ID 55 does not change
            if($env:BRS_MODE -eq "PROD") {
                # prod
                $descr_scrub = $descr_scrub.Replace('workgroups/group/55', ('workgroups/group/{0}' -f $rec.GROUP_ID) )
            }
            else {
                # QA
                $descr_scrub = $descr_scrub.Replace('team.hsa.ca/workgroups/group/55', ('team-qa.hsa.ca/workgroups/group/{0}' -f $rec.GROUP_ID) )
            }
        }
        
		$params_addtask = "T[TITLE]={0}&T[DEADLINE]={1}&T[START_DATE_PLAN]={2}&T[END_DATE_PLAN]={3}&T[PRIORITY]={4}&T[TAGS]={5}&T[ALLOW_CHANGE_DEADLINE]=Y&T[PARENT_ID]={6}&T[RESPONSIBLE_ID]={7}&T[GROUP_ID]={8}" -f $rec.TITLE, $deadline, $rec.START_DATE_PLAN, $rec.END_DATE_PLAN, $rec.PRIORITY, $rec.TAGS, $parent_id, $rec.RESPONSIBLE_ID, $rec.GROUP_ID
        #
        #$params_addtask
        #([System.Text.Encoding]::UTF8.GetBytes($params_addtask)) 
        #
        $res_create = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.item.add/") -Body ([System.Text.Encoding]::UTF8.GetBytes($params_addtask)) 
        $task_id_new = $res_create.result
                
        $params_updatetask = "TASKID={0}&T[DESCRIPTION]={1}" -f $task_id_new, $descr_scrub
        $res_update = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.item.update/") -Body ([System.Text.Encoding]::UTF8.GetBytes($params_updatetask)) 

        # update new lookups to map org task relationships to new
        if( -not ($task_id_hash.ContainsKey($rec.bx_task_id_org)) ) {$task_id_hash.Add($rec.bx_task_id_org, $task_id_new)}
        if( -not ($parent_hash.ContainsKey($rec.TAGS)) ) {$parent_hash.Add($rec.TAGS,$task_id_new)}

        # create checklist
        if($rec.bx_checklist.length -gt 0) {
            $check_array = $rec.bx_checklist.split('|')
            ForEach($check in $check_array) {
                $check_scrub = $check.Replace('&', '%26')
                $check_param = "ID={0}&F[TITLE]={1}" -f $task_id_new, $check_scrub
                #
                #$check_param
                #
                $res_check = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.checklistitem.add/") -Body ([System.Text.Encoding]::UTF8.GetBytes($check_param))
            }
        }


        # add gantt relationships
        $link_param = @{
            taskIdFrom = $task_id_hash[$rec.bx_task_id_depends_on_org]
            taskIdTo = $task_id_hash[$rec.bx_task_id_org]
            linkType = 2
        }

        if($rec.bx_task_id_depends_on_org -gt 0) {   
            $res_link = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.dependence.add/") -Body $link_param 
            $id_new = $res_link.result
        }

        # close unneeded design tasks (reversible)
        if($rec.bx_task_id_parent_org -eq $design_parent_id) {   
            # close xray
            if($rec.bx_xray_qty -eq 0 -and $design_xray_list.Contains($rec.bx_task_id_org) ) {   
                $res_close = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.item.complete/") -Body @{TASKID=$task_id_new} 
            }
            # close newreno
            if($rec.bx_newreno_qty -eq 0 -and $design_newreno_list.Contains($rec.bx_task_id_org) ) {   
                $res_close = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.item.complete/") -Body @{TASKID=$task_id_new} 
            }
        }

        # done
        [PSCustomObject]@{
            title = $rec.TITLE
            fixed = $rec.DESCRIPTION.contains('&')
            desc_org = $rec.DESCRIPTION
            desc_new = $descr_scrub
            BX_DESC_LEN = $descr_scrub.length
            BX_CHECK_COUNT = $check_array.count

            BX_GROUP_ID = $rec.GROUP_ID
            BX_TASK_ID_OLD = $rec.bx_task_id_org
            BX_TASK_ID_NEW = $task_id_hash[$rec.bx_task_id_org]
        }
    }
}
