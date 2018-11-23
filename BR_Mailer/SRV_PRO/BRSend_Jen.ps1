# Send Service Email
# created by jli
# 20 Nov 18, tmc, mail from updated
# 21 Nov 18, jli, standardize mail sending

# todo:  
# make this parameter driven (body, emails, attach) = Param 1 = start path, Param 2 = Max group (1 - 100)

# log status, performance   
# Set email server 

# get global parameters
$global_smtp_server=$env:BR_Mailing_Server
$global_debug_mode=$env:BRS_MODE


# Set job parameters path
$path=$env:br_mailing_path
# $path=$start_path
$path=$path + 'SRV_PRO\'

#get/set job variables
$job_code="SRV_PRO"
$job_run_mode="Group"
#$job_group_count=2
$job_mail_from = "Trevor.Crowley@henryschein.ca"

#set up log file
$job_log_file=$path + 'log\SRV_PRO_LOG.txt'


# performace log start
$startTime = Get-date
$startLog = $job_code +" - Log - " + $startTime
write-output  $startLog | Add-Content $job_log_file

#loop through all group folders
foreach($_ in (Get-ChildItem $path)){

if($_.PSIsContainer -AND $_.name -ne "Log"){


# Load job params
$list=import-csv ($path+$_.name + '\Mail_List.csv')

# Load message body as HTML
$mail_body=get-content ($path +$_.name+'\Mail_Body.htm') | out-string

# Set from / Subject
#$mail_from = 'David.Pinto@henryschein.ca'
#$job_mail_from = $list[0].job_mail_from   

$mail_subject=$list[0].mail_subject

# build attachments list based on param first entry (max 3)
$attachments=@()
if($list[0].mail_attachment_1 ) {
    $attachments += $list[0].mail_attachment_1 
}

if($list[0].mail_attachment_2) {
    $attachments += $list[0].mail_attachment_2
}

if($list[0].mail_attachment_3) {
    $attachments += $list[0].mail_attachment_3
}

# convert attachement array to named list           
$mail_attachments = @{}
$mail_attachments['Attachments'] = $attachments



# build mail list 
$mail_to=@()
foreach ($i in $list)
{	
    $mail_to += $i.mail_to -split ','
}

#debug
#Write-Host '$global_smtp_server =' $global_smtp_server '$job_mail_from =' $job_mail_from '$mail_subject=' $mail_subject '@mail_attachments =' @mail_attachments '$mail_to=' $mail_to


# Send email
try { 

    send-mailmessage -smtpserver $global_smtp_server -to $mail_to -from "JenniferTest@henryschein.ca"  -subject $mail_subject -body $mail_body -bodyashtml @mail_attachments     
    #write log message
    $logmessage = "Completed - email sent " + "From " + $job_mail_from + " To " + $mail_to + " with attachment - " +$attachments+  " - "+  $((Get-Date).ToShortDateString())
    write-output $logmessage | Add-Content $job_log_file
    
} 
catch {
    #write log message
    $logmessage = "Failed - email sent " +  "From " + $job_mail_from + " To " + $mail_to + " with attachment - " +$attachments + " - " + $((Get-Date).ToShortDateString()) 
    write-output  $logmessage | Add-Content $job_log_file
    

}
 
# todo:  log status, performance   


}}