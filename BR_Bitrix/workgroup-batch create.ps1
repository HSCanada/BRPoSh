# import project list
$list=import-csv ('S:\BR\Jennifer\Project\RestAPI\list.csv') 

foreach ($eachline in $list)
{	
        $groupname =$eachline.name
        $url= "https://team-qa.hsa.ca/rest/1/2v21zmqf6rtcp2f2/sonet_group.create.json?NAME="+$groupname+" - "+(Get-Date).ToString("d",$dede)
        $url =$url +"&DESCRIPTION=Test%20desr&VISIBLE=Y&OPENED=N&INITIATE_PERMS=K&PROJECT=Y&PROJECT_DATE_FINISH="+'2040-12-30'+"&PROJECT_DATE_START="+(Get-Date).ToString("d",$dede)
   

        #$url = "https://team-qa.hsa.ca/rest/1/2v21zmqf6rtcp2f2/sonet_group.create.json?NAME=Equipment-"+$i+"%20sonet%20group&VISIBLE=Y&OPENED=Y&INITIATE_PERMS=K&PROJECT=Y"

        #curl -o $url
       # curl -s -o /dev/null -w $url
       # curl -s -o /dev/null -I -w "%{http_code}" $url
         curl -i $url
       #$i=$i+1

}
