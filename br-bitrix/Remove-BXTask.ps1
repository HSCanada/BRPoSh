Param(
    [Parameter( Mandatory=$True, ValueFromPipeline=$True) ] 
    $pipelineInput
)
 

Begin {
    $url_base = $env:bx_webhook_url
}

PROCESS {
            
    ForEach ($rec in $pipelineInput) {
        Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.item.delete/") -Body @{TASKID=$rec}
       

    }
}
