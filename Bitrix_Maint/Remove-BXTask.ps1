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
}

PROCESS {
            
    ForEach ($rec in $pipelineInput) {
        Invoke-RestMethod -Method 'Post' -Uri ($url_base + "task.item.delete/") -Body @{TASKID=$rec}
    }
}
