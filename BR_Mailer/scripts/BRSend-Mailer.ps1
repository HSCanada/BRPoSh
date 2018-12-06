# Send Service Email
# created by jli
# 20 Nov 18, tmc, mail from updated
# 21 Nov 18, jli, standardize mail sending

# todo:  
# make this parameter driven (body, emails, attach) = Param 1 = start path, Param 2 = Max group (1 - 100)

# log status, performance   
# Set email server 

#power shell parameter

param([Parameter(Position=0,mandatory=$true)][string]$job_code)

# ***TC - make the script fail if no parameters, and SHOW the params 
# Assume G type

# get global parameters
$global_smtp_server=$env:BR_Mailing_Server
$global_debug_mode=$env:BRS_MODE

# Set job parameters path
$br_mailer_path=$env:br_mailing_path

# set start_path
$job_path=$br_mailer_path +  $job_code +"\"

 #set up log file
$job_log_file=$job_path + 'log\Mail_Log.txt'



#beging log message
$job_startLog_message = $job_code +" - Log - " + (Get-Date).ToLocalTime()
write-output  $job_startLog_message | Add-Content $job_log_file


# ** TC Assume G for now - we do not have FSC mode, comment out
#if($job_run_mode="G")
#{

    #loop through all group folders
    foreach($group in (Get-ChildItem $job_path)){

        if($group.PSIsContainer -AND $group.name  -like 'G[01-99]*'){


            # Load job params
            $list=import-csv ($job_path+$group.name + '\Mail_List.csv')           
    

            # Load message body as HTML
            $mail_body=get-content ($job_path +$group.name+'\Mail_Body.htm') | out-string

            # set job_mail_from
            $job_mail_from = $list[0].job_mail_from

             # get message subject
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


            $i=0
            
            # build mail list 
            $mail_to=@()

            do{

                foreach ($eachline in $list[$i])
                {	
                    $mail_to += $eachline.mail_to -split ','
                }
                $i=$i +1
 
            }while ($i-le $list.count-1)


                #debug
                #Write-Host '$global_smtp_server =' $global_smtp_server '$job_mail_from =' $job_mail_from '$mail_subject=' $mail_subject '@mail_attachments =' @mail_attachments '$mail_to=' $mail_to


                # Send email
            try { 

                send-mailmessage -smtpserver $global_smtp_server -to $mail_to -from $job_mail_from -subject $mail_subject -body $mail_body -bodyashtml @mail_attachments     
                #write log message 
                $job_success_message = "Completed - email sent from |" +$job_mail_from + "|To|" + $mail_to + "| with attachment |"+$attachments+  "|"+  (Get-Date).ToLocalTime()
                write-output $job_success_message | Add-Content $job_log_file
    
            } 
            catch {
                #write log message
                $job_failure_message = "Failed - email sent from |" +$job_mail_from + "|To|" + $mail_to + "| with attachment |"+$attachments+  "|"+  (Get-Date).ToLocalTime()  
                write-output  $job_failure_message | Add-Content $job_log_file
    

           }
               
        }
    }
#}