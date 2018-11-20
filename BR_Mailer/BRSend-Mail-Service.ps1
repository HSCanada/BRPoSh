# Send Service Email
# created by jli
# 16 Nov 18, tmc, mail from updated

# todo:  
#  group email?
#  make parameter driven (body, emails, attach) -- flowchat

# Set email server 
$smtp=$env:BR_Mailing_Server

# Set email parameters location
$path=$env:br_mailing_path
$path=$path + 'service\'

# Load mailing list
$list=import-csv ($path + 'Service_Mailing_List.csv')

# Load message body
$body=get-content ($path +'Email.Msg.Body\Service - Mail Body3.htm') | out-string

# performace log start
$startTime = Get-date
$startLog = 'Service-' +$startTime

# mail for each user
foreach ($i in $list)
{	
    # build up attachments array (max 3)
    $attachments=@()

    if($i.attach1 ) {
        $attachments += $i.attach1 
    }
          
    if($i.attach2) {
        $attachments += $i.attach2 
    }

    if($i.attach3) {
        $attachments += $i.attach3 
    }

    # convert attachement array to named list           

	$params = @{}
	$params['Attachments'] = $attachments

    # build mail send (can be list)
    $emailarray  = $I.EMAIL -split ','


    # Send email
    try { 
        Write-Host $emailarray 
#        send-mailmessage -smtpserver $smtp -to $emailarray -from "David.Pinto@henryschein.ca" -subject $i.subject -body $body -bodyashtml @params 
    } 
    catch {
        echo "sending message failed"
    }

} # for

# testing
#$mailto = 'trevor.crowley@henryschein.ca'
 $mailto = 'trevor.crowley@henryschein.ca', 'jennifer.li@henryschein.ca'

send-mailmessage -smtpserver $smtp -to $mailto -from "David.Pinto@henryschein.ca" -subject $i.subject -body $body -bodyashtml @params 

 
   



