Param(
    [Parameter( Mandatory=$True, ValueFromPipeline=$True) ] 
    $pipelineInput
)
 

Begin {
    $url_base = $env:bx_webhook_url

    # move this down  to reset hash at start of new group TBD
    $parent_hash = $null
    $parent_hash = @{}

    $task_id_hash = $null
    $task_id_hash = @{}

}

PROCESS {
            
    ForEach ($rec in $pipelineInput) {

#        if ($rec.PRIORITY -eq 2) { $rec.DEADLINE = $rec.END_DATE_PLAN }

        # reset hash at start of new group...

        $parent_id = $parent_hash[$rec.TAGS]
        
		$params_addtask = "T[TITLE]={0}&T[DESCRIPTION]={1}&T[PRIORITY]={2}&T[TAGS]={3}&T[PARENT_ID]={4}&T[RESPONSIBLE_ID]={5}&T[GROUP_ID]={6}" -f $rec.TITLE, $rec.DESCRIPTION, $rec.PRIORITY, $rec.TAGS, $parent_id, $rec.RESPONSIBLE_ID, $rec.GROUP_ID
#		$params_addtask = "T[TITLE]={0}&T[DESCRIPTION]={1}&T[DEADLINE]='2019-06-06T12:12:12'&T[START_DATE_PLAN]='{3:yyyyMMdd}'&T[END_DATE_PLAN]='{4:yyyyMMdd}'T[PRIORITY]={5}&T[TAGS]={6}&T[PARENT_ID]={7}&T[RESPONSIBLE_ID]={8}&T[DEPENDS_ON]={9}&T[GROUP_ID]={10}" -f $rec.TITLE, $rec.DESCRIPTION, $rec.DEADLINE, $rec.START_DATE_PLAN, $rec.END_DATE_PLAN, $rec.PRIORITY, $rec.TAGS, $parent, $owner_id, $depends, $group_id
#       $params_addtask
            
        $res_create = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.item.add/") -Body $params_addtask 
        $task_id_new = $res_create.result

        # update new lookups to map org task relationships to new
        if( -not ($task_id_hash.ContainsKey($rec.bx_task_id_org)) ) {$task_id_hash.Add($rec.bx_task_id_org, $task_id_new)}
        if( -not ($parent_hash.ContainsKey($rec.TAGS)) ) {$parent_hash.Add($rec.TAGS,$task_id_new)}

        # date dates here?  TBD

    }

    # add gantt relationships
    ForEach ($rec in $pipelineInput) {

        $link_param = @{
            taskIdFrom = $task_id_hash[$rec.bx_task_id_depends_on_org]
            taskIdTo = $task_id_hash[$rec.bx_task_id_org]
            linkType = 2
        }

        if($rec.bx_task_id_depends_on_org -gt 0) {   
            $res_link = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.dependence.add/") -Body $link_param 
            $id_new = $res_link.result
        }

        [PSCustomObject]@{

            BX_GROUP_ID = $rec.GROUP_ID
            BX_TASK_ID_OLD = $rec.bx_task_id_org
            BX_TASK_ID_NEW = $task_id_hash[$rec.bx_task_id_org]
        }
    }

}


