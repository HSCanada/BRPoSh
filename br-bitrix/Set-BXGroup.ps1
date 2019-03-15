Param(
        [Parameter(
                Mandatory=$True,
                ValueFromPipeline=$True) ]

        $pipelineInput
)
 
        Begin {
        Import-Module -Name .\TervisMicrosoft.PowerShell.Utility.psm1
		$url_base = $env:bx_webhook_url
		$url_create = $url_base + "sonet_group.create/"
		$url_invite = $url_base + "sonet_group.user.invite/"
		$url_setowner = $url_base + "sonet_group.setowner/"
        }
        PROCESS {

                ForEach ($rec in $pipelineInput) {
			# create group
			$body = $rec | ConvertTo-HashTable
			$res_create = Invoke-RestMethod -Method 'Post' -Uri $url_create -Body $body 
			$group_id = $res_create.result

			# assign users to group
			$params_invite = @{
			    GROUP_ID = $group_id
			    USER_ID = $rec.bx_user_id_fsc
			    MESSAGE = "Invitation"
			}
			$res_invite = Invoke-RestMethod -Method 'Post' -Uri $url_invite -Body $params_invite


			$params_invite = @{
			    GROUP_ID = $group_id
			    USER_ID = $rec.bx_user_id_ess
			    MESSAGE = "Invitation"
			}
			$res_invite = Invoke-RestMethod -Method 'Post' -Uri $url_invite -Body $params_invite

			$params_invite = @{
			    GROUP_ID = $group_id
			    USER_ID = $rec.bx_user_id_branch
			}
			$res_invite = Invoke-RestMethod -Method 'Post' -Uri $url_setowner -Body $params_invite

			# return new group for post processing
                        [PSCustomObject]@{
			    BX_SHIPTO = $rec.bx_shipto
			    BX_GROUP_ID = $group_id
			    BX_SET_DATE = $rec.PROJECT_DATE_START
                        }
               }
        }


