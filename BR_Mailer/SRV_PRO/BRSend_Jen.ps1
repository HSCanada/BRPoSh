# Send Service Email
# created by jli
# 20 Nov 18, tmc, mail from updated

# todo:  
# make this parameter driven (body, emails, attach) = Param 1 = start path, Param 2 = Max group (1 - 100)

# log status, performance   
# Set email server 

$mail_smtp=$env:BR_Mailing_Server

# Set job parameters path
$path=$env:br_mailing_path
$path=$path + 'service\'
$group_max = 1  

# Load job params
$list=import-csv ($path + 'Service_Mailing_List.csv')

# Load message body as HTML
$mail_body=get-content ($path +'Email.Msg.Body\Service - Mail Body.htm') | out-string

# Set from / Subject
$mail_from = 'David.Pinto@henryschein.ca'
$mail_subject=$list[0].subject

# build attachments list based on param first entry (max 3)
$attachments=@()
if($list[0].attach1 ) {
    $attachments += $list[0].attach1
}

if($list[0].attach2) {
    $attachments += $list[0].attach2
}

if($list[0].attach3) {
    $attachments += $list[0].attach3
}

# convert attachement array to named list           
$mail_param = @{}
$mail_param['Attachments'] = $attachments


# performace log start
$startTime = Get-date
$startLog = 'Service-' +$startTime

# build mail list 
$mail_to=@()
foreach ($i in $list)
{	
    $mail_to += $i.EMAIL -split ','
}

#debug
#Write-Host '$mail_smtp =' $mail_smtp '$mail_from =' $mail_from '$mail_subject=' $mail_subject '@mail_param =' @mail_param '$mail_to=' $mail_to

# Send email
try { 
    send-mailmessage -smtpserver $mail_smtp -to $mail_to -from $mail_from -subject $mail_subject -body $mail_body -bodyashtml @mail_param
} 
catch {
    # set fail code & message here 
}
 
# todo:  log status, performance   