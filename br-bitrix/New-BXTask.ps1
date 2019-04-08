Param(
    [Parameter( Mandatory=$True, ValueFromPipeline=$True) ] 
    $pipelineInput
)
 

Begin {
    $url_base = $env:bx_webhook_url
    $group_id_current = -1

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
        
		$params_addtask = "T[TITLE]={0}&T[DESCRIPTION]={1}&T[DEADLINE]={2}&T[START_DATE_PLAN]={3}&T[END_DATE_PLAN]={4}&T[PRIORITY]={5}&T[TAGS]={6}&T[PARENT_ID]={7}&T[RESPONSIBLE_ID]={8}&T[GROUP_ID]={9}" -f $rec.TITLE, $rec.DESCRIPTION, $deadline, $rec.START_DATE_PLAN, $rec.END_DATE_PLAN, $rec.PRIORITY, $rec.TAGS, $parent_id, $rec.RESPONSIBLE_ID, $rec.GROUP_ID
            
        $res_create = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.item.add/") -Body $params_addtask 
        $task_id_new = $res_create.result

        # update new lookups to map org task relationships to new
        if( -not ($task_id_hash.ContainsKey($rec.bx_task_id_org)) ) {$task_id_hash.Add($rec.bx_task_id_org, $task_id_new)}
        if( -not ($parent_hash.ContainsKey($rec.TAGS)) ) {$parent_hash.Add($rec.TAGS,$task_id_new)}

        # checklist updates here?  TBD

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

        # done
        [PSCustomObject]@{

            BX_GROUP_ID = $rec.GROUP_ID
            BX_TASK_ID_OLD = $rec.bx_task_id_org
            BX_TASK_ID_NEW = $task_id_hash[$rec.bx_task_id_org]
        }
    }
}
