
$params_create = @{

    shipto = 3795447
    bx_user_id_fsc = 6
    bx_user_id_ess = 4
    bx_user_id_branch = 33
    NAME = "Elsaraj Dentistry Prof Corp - 3795447 - TBD"
    DESCRIPTION = "1596 Walkley Rd |  | Ottawa | ON | (613) 738-7211  | jonathan hollink | bev robertson"
    VISIBLE = "Y"
    OPENED = "N"
    KEYWORDS = "ottawa"
    INITIATE_PERMS = "K"
    PROJECT = "Y"
    PROJECT_DATE_START  = "31/03/2019 12:00:00 AM"
    PROJECT_DATE_FINISH = "31/12/2040 12:00:00 AM"
    
}



$url_base = $env:bx_webhook_url

$url_create = $url_base + "sonet_group.create/"
$url_invite = $url_base + "sonet_group.user.invite/"


$res_create = Invoke-RestMethod -Method 'Post' -Uri $url_create -Body $params_create
$group_id = $res_create.result


$params_invite = @{
    GROUP_ID = $group_id
    USER_ID = $params_create.bx_user_id_fsc
    MESSAGE = "Invitation"
}
$res_invite = Invoke-RestMethod -Method 'Post' -Uri $url_invite -Body $params_invite


$params_invite = @{
    GROUP_ID = $group_id
    USER_ID = $params_create.bx_user_id_ess
    MESSAGE = "Invitation"
}
$res_invite = Invoke-RestMethod -Method 'Post' -Uri $url_invite -Body $params_invite

$params_invite = @{
    GROUP_ID = $group_id
    USER_ID = $params_create.bx_user_id_branch
    MESSAGE = "Invitation"
}
$res_invite = Invoke-RestMethod -Method 'Post' -Uri $url_invite -Body $params_invite

$output = @{
    SHIPTO = $params_create.shipto
    BX_GROUP_ID = $group_id
    BX_SET_DATE = $params_create.PROJECT_DATE_START
}


write-output $output

