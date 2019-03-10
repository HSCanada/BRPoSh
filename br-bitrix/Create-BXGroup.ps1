
param(
    [parameter(
        Mandatory         = $true,
        ValueFromPipeline = $true)]
    $pipelineInput
)

$url_base = $env:bx_webhook_url

$url_create = $url_base + "sonet_group.create/"
$url_invite = $url_base + "sonet_group.user.invite/"
$url_setowner = $url_base + "sonet_group.usonet_group.setowner/"

# create group
$res_create = Invoke-RestMethod -Method 'Post' -Uri $url_create -Body $pipelineInput
$group_id = $res_create.result

# assign users to group
$params_invite = @{
    GROUP_ID = $group_id
    USER_ID = $pipelineInput.bx_user_id_fsc
    MESSAGE = "Invitation"
}
$res_invite = Invoke-RestMethod -Method 'Post' -Uri $url_invite -Body $pipelineInput

$params_invite = @{
    GROUP_ID = $group_id
    USER_ID = $pipelineInput.bx_user_id_ess
    MESSAGE = "Invitation"
}
$res_invite = Invoke-RestMethod -Method 'Post' -Uri $url_invite -Body $pipelineInput

$params_invite = @{
    GROUP_ID = $group_id
    USER_ID = $piplineInput.bx_user_id_branch
}
$res_invite = Invoke-RestMethod -Method 'Post' -Uri $url_setownder -Body $pipelineInput

# return new group for post processing
$output += @{
    SHIPTO = $pipelineInput.bx_shipto
    BX_GROUP_ID = $group_id
    BX_SET_DATE = $pipelineInput.PROJECT_DATE_START
}

write-output $output

