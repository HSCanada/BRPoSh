<#
Param(
        [Parameter(
                Mandatory=$True,
                ValueFromPipeline=$True) ]

        $pipelineInput
)
#>

        Begin {
		$url_base = $env:bx_webhook_url
        $url_folderget = $url_base + "disk.folder.get/"
        $url_addsubfolder = $url_base + "disk.folder.addsubfolder/"
		$url_create = $url_base + "sonet_group.create/"
		$url_invite = $url_base + "sonet_group.user.invite/"
		$url_setowner = $url_base + "sonet_group.setowner/"
        }
        PROCESS {


			# assign users to group
			$params_test1 = @{
			    GROUP_ID = $group_id
			    USER_ID = $rec.bx_user_id_fsc
			    MESSAGE = "Invitation"
			}

#            id: 8,
#            data: {
#                NAME: 'New sub folder'
#            }





#			$res = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "disk.storage.getlist/")
			$res = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "sonet_group.get/")


<#
ID             : 41
NAME           : MDM rollout
CODE           : 
MODULE_ID      : disk
ENTITY_TYPE    : group
ENTITY_ID      : 15
ROOT_OBJECT_ID : 129  <= this is the folder
#>

#			$res = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "disk.storage.get/") -Body @{id = 41}
#            $res.result


# not useful
#			$res = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "disk.storage.get/") -Body @{id = 2}


#			$res = Invoke-RestMethod -Method 'Post' -Uri $url_folderget 
#			$res = Invoke-RestMethod -Method 'Post' -Uri $url_folderget -Body $params_invite


        }


