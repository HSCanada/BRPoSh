Param(
    [Parameter( Mandatory=$True, ValueFromPipeline=$True) ] 
    $pipelineInput
)
 
Begin {
#    Import-Module -Name .\TervisMicrosoft.PowerShell.Utility.psm1
    $url_base = $env:bx_webhook_url
    $body = $Null
}
PROCESS {
            
    ForEach ($rec in $pipelineInput) {

        # store dates for post pipeline to sql save state
        $pr_start = $rec.PROJECT_DATE_START
        $pr_finish = $rec.PROJECT_DATE_FINISH

        $body = [ordered]@{
            NAME = $rec.NAME
            DESCRIPTION = $rec.DESCRIPTION
            VISIBLE= $rec.VISIBLE
            OPENED = $rec.OPENED
            KEYWORDS = $rec.KEYWORDS
            INITIATE_PERMS = $rec.INITIATE_PERMS
            PROJECT= $rec.PROJECT
            PROJECT_DATE_START= $rec.PROJECT_DATE_START
            PROJECT_DATE_FINISH= $rec.PROJECT_DATE_FINISH
        }

        # projects maintained for 2 years 
        $body.PROJECT_DATE_START = $body.PROJECT_DATE_START.addyears(-1)
        $body.PROJECT_DATE_FINISH = $body.PROJECT_DATE_FINISH.Addyears( 1)

        # update tags / desc?            
        if ($rec.cadcam_sales -gt 0) { $body.KEYWORDS += ', cadcam' }
        if ($rec.hitech_sales -gt 0) { $body.KEYWORDS += ', hitech' }
        if ($rec.large_equip_sales -gt 0) { $body.KEYWORDS += ', large_equip' }
        if ($rec.dentrix_sales -gt 0) { $body.KEYWORDS += ', dentrix' }
        if ($rec.design_sales -gt 0) { $body.KEYWORDS += ', design' }
        # test
        #$body
            
        $res_create = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "sonet_group.create/") -Body $body 
        $group_id = $res_create.result

        <#
        # add folders here

        $res_folder = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "disk.storage.get/") -Body @{id = $group_id}
        $folder_id = $res_folder.result.ROOT_OBJECT_ID

        $res_folder = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "disk.folder.addsubfolder/") -Body @{id = $folder_id; data = @{NAME = 'testdir'} }

        A-design
        B-coordination-contract
        B-coordination-financing
        B-coordination-order-details
        C-pre-install-checklists
        D-post-install-follow-up
        
        # assign users to group
        $params_invite = @{ GROUP_ID = $group_id; USER_ID = $rec.bx_user_id_fsc; MESSAGE = "Invitation" }
        $res_invite = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "sonet_group.user.invite/") -Body $params_invite
        #>

        # return new group for post processing


        [PSCustomObject]@{
            BX_SHIPTO = $rec.bx_shipto
            BX_GROUP_ID = $group_id
            PROJECT_DATE_START = $pr_start
            PROJECT_DATE_FINISH = $pr_finish
            bx_cps_code = $rec.bx_cps_code
            bx_ess_code = $rec.bx_ess_code
            bx_dts_code = $rec.bx_dts_code
            bx_fsc_code = $rec.bx_fsc_code
        }
    }
}


