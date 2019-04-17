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


#$filter_parm = @{'%name'='chad'}


#			$res = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "disk.folder.getchildren/") -Body @{id=2}
#            $res.result
#			(Invoke-RestMethod -Method 'Post' -Uri ($url_base + "sonet_group.get/")).result


<#

ID             : 41 <- don't know ?
NAME           : MDM rollout
CODE           : 
MODULE_ID      : disk
ENTITY_TYPE    : group
ENTITY_ID      : 15 <= work group Id (url path)
ROOT_OBJECT_ID : 129  <= this is the folder

#>

            # 2
#			$res = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "disk.storage.get/") -Body @{id = 699}
#            $res.result

            # 1
# https://team-qa.hsa.ca/rest/1/2v21zmqf6rtcp2f2/disk.folder.addsubfolder?id=1901&data[NAME]=newfiler2

# https://team-qa.hsa.ca/rest/1/2v21zmqf6rtcp2f2/disk.storage.getlist?filter[%NAME]=MDM
		#	$res = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "disk.folder.addsubfolder/") -Body ("id={0}&data[NAME]={1}" -F 1901, "Folder 7")
         #   $res.result


			#3
#            $res = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "disk.storage.getlist/")
#            $res.result

            #4 how to call #3 with filter parms (group id or name)"
            #$res = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "disk.storage.getlist/") -Body ("filter[%NAME]={0}" -F "Review")    
            $res = Invoke-RestMethod -Method 'Post' -Uri ($url_base + "disk.storage.getlist/") -Body ("filter[ENTITY_ID]={0}&filter[ENTITY_TYPE]={1}" -F 19,"group")          
            $res.result





        }


