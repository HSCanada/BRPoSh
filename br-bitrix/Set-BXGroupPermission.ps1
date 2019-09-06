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

}

PROCESS {
            
    ForEach ($rec in $pipelineInput) {
            
        # assign users to group
        $params_invite = @{ GROUP_ID = $rec.GROUP_ID; USER_ID = $rec.USER_ID; MESSAGE = "Invitation" }
#        $params_invite
        $res_invite = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "sonet_group.user.invite/") -Body $params_invite

        # reset hash at start of new group
        if ($group_id_current -ne $rec.GROUP_ID) {
            # done
            [PSCustomObject]@{
                BX_SHIPTO = $rec.bx_shipto
                BX_GROUP_ID = $rec.GROUP_ID
            }
            $group_id_current = $rec.GROUP_ID
        }
    }
}
