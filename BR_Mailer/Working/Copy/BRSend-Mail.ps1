
$smtp=$env:BR_Mailing_Server

$path=$env:br_mailing_path  #(get-location) 


$Logfile = "$path" + "\log\mailing.log" #attach\" #"D:\Apps\Logs\$(gc env:computername).log"

Function LogWrite
{
   Param ([string]$logstring)

   Add-content $Logfile -value $logstring
}


Clear-Host
if (!(test-path HKLM:\SYSTEM\CurrentControlSet\Services\Eventlog\Application\BRC))`
    {new-eventlog -Logname Application -source BRC `
    -ErrorAction SilentlyContinue}

$list=import-csv ($path + "mailing list v6.csv")

#$list=import-csv ($path + "J051_TOP15_FSC\"+"mailing list - Top15 - test.csv")

#$list=import-csv ($path + "mailing list v6 - ME.csv")
#$list=import-csv ($path + "mailing list FSC comm.csv")
#$list=import-csv ($path + "mailing list FSC comm - test.csv")
#$list=import-csv ($path + "mailing list EST comm - test.csv")
#$list=import-csv ($path + "mailing list EST comm.csv")

$startTime = Get-date
#$startLog = 'Top15 FSC -' +$startTime
$startLog = 'Branch Daily Sales -' +$startTime

#'Write-Eventlog -Logname Application -Message $startLog -Source 'TOP15FSC'
write-eventlog -logname Application -message $startlog -source BRC -ENTRYTYPE information -EventId 1 -category 0 

foreach ($i in $list)
{	
	if($i.flag -eq 1 -and $i.count -gt 0) {
		
		 
        if($i.attach1 ){
	        $attachments=@()
            $attach=@()
  		   # $attachments +="$path" + "attach\" + $i.attach1 
            $attachments += $i.attach1 

            $attach +=$i.attach1

           echo $attachments
          }
        if($i.attach2){
            $attachments=@()
            $attach=@()
		    #$attachments += "$path" + "attach\" +$i.attach1 
            $attachments += $i.attach1 
            $attach +=$i.attach1
            #$attachments += "$path" + "attach\" +$i.attach2
            $attachments += $i.attach2 
            $attach +=$i.attach2
             echo $attachments

        }
		
        if($i.attach3){

		
		    $attachments=@()
            $attach=@()

	       # $attachments += "$path" + "attach\" +$i.attach1 
            $attachments += $i.attach1 
            $attach +=$i.attach1
		    #$attachments += "$path" + "attach\" + $i.attach2 
            $attachments += $i.attach2 
            $attach +=$i.attach2
		    #$attachments += "$path" + "attach\" + $i.attach3
            $attachments += $i.attach3 
            $attach +=$i.attach3
            echo $attachments
         
        }                                           
        echo $attachments	

	    $params = @{}
	
	    $params['Attachments'] = $attachments
	
        $emailarray  = $I.EMAIL -split ','

        try{
		
	        send-mailmessage -smtpserver $smtp -to $emailarray -from "businessreporting.canada@henryschein.ca" -subject $i.subject -body $i.msg -bodyashtml -priority  high @params 
            #write-eventlog -logname Application -message ( 'Top15 FSC -' +$startTime+ '  to  '  + $i.email + "    " + $attach ) -source BRC -ENTRYTYPE information -EventId 1 -category 0
            write-eventlog -logname Application -message ( 'Branch Daily Sales -' +$startTime+ '  to  '  + $i.email + "    " + $attach ) -source BRC -ENTRYTYPE information -EventId 1 -category 0
            #LogWrite ($attachments  + " sent to " + $i.email + " on success")
            #echo $i.msg + "sent to" + $i.email
         }
        catch
         {
             echo "sending message failed"
            # write-eventlog -logname Application -message ('Top15 FSC -' +$startTime+ '  to  '  + $i.email + "   - Fail to send") -source BRC -ENTRYTYPe FailureAudit -EventId 2 -category 1
             write-eventlog -logname Application -message ('Branch Daily Sales -' +$startTime+ '  to  '  + $i.email + "   - Fail to send") -source BRC -ENTRYTYPe FailureAudit -EventId 2 -category 1

        }
 
    }

    elseif($i.flag -eq 1) {
    
        $emailarray  = $I.EMAIL -split ','
            try{
                send-mailmessage -smtpserver $smtp -to $emailarray  -from "businessreporting.canada@henryschein.ca" -subject $i.subject -body $i.msg -bodyashtml -priority  high 
                #write-eventlog -logname Application -message ( 'Top15 FSC -' +$startTime+ '  to  '  + $i.email ) -source BRC -ENTRYTYPE information -EventId 1 -category 0
                write-eventlog -logname Application -message ( 'Branch Daily Sales -' +$startTime+ '  to  '  + $i.email ) -source BRC -ENTRYTYPE information -EventId 1 -category 0
                #LogWrite ($attachments + "sent to" + $i.email)
                #echo $i.msg + "sent to" + $i.email
            }
            catch{
                    echo "sending message failed"
                    #write-eventlog -logname Application -message ('Top15 FSC -' +$startTime+ '  to  '  + $i.email + "   - Fail to send") -source BRC -ENTRYTYPe FailureAudit -EventId 2 -category 1
                    write-eventlog -logname Application -message ('Branch Daily Sales -' +$startTime+ '  to  '  + $i.email + "   - Fail to send") -source BRC -ENTRYTYPe FailureAudit -EventId 2 -category 1
            }
      }
      else
       
      {
            echo "flag set to 0, no message sent"
      }
    

}


