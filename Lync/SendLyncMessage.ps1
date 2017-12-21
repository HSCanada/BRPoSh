$assemblyPath="C:\Program Files\Microsoft office\office15\Lyncsdk\assemblies\desktop\Microsoft.Lync.Model.dll"
Import-Module $assemblyPath
$lastname=38
$IMType =1
$PlainText =0

$cl=[Microsoft.Lync.Model.LyncClient]::GetClient()

$conv= $cl.conversationmanager.addconversation()

$gs=$cl.ContactManager.Groups

$i=0

foreach($g in $gs)
{
    foreach($contact in $g)
    {
        if($contact.getcontactinformation("LastName") -eq "Crowley")
        #if($contact.uri -eq "sip:BusinessReporting.Canada@henryschein.ca")
        {
            $i++
            $null = $conv.addparticipant($contact)

            break
        }
    }
 
    if ($i -gt 0) {break}
}
 
$d = New-Object "System.Collections.Generic.Dictionary[Microsoft.Lync.Model.Conversation.InstantMessageContentType,String]"
#$d.Add($PlainText, "This message is sent by Powershell - Jen")
#$d.Add($PlainText, "https://goo.gl/reEiX6")
$d.add($PlainText,"https://goo.gl/xW5mU7")
#$d.Add($PlainText, "https://henryscheininc-my.sharepoint.com/personal/opportunitiesnow_henryschein_ca/Documents/Forms/All.aspx?RootFolder=%2Fpersonal%2Fopportunitiesnow_henryschein_ca%2FDocuments%2FzDev&FolderCTID=0x0120006F4C8D083CFFAB4EA3F39AC878F0D3C6&View=%7B145C7C60-8EDF-46D2-B9E3-532F7F5A11A1%7D")

 
$m = $conv.Modalities[$IMType]
#$null = $m.BeginSendMessage("testing",[AsyncCallback]$null,$d)

#$myCallback = [AsyncCallback]{
 # param( $asyncResult)
  # callback code
  #if ($asyncResult.isCompleted) {
   # Write-Host "Message Sent"
  #}
#}

$null = $m.BeginSendMessage($d,$null,$d)

       