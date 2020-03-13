
$smtp=$env:BR_Mailing_Server

$path=$env:br_mailing_path  #(get-location) 


$Logfile = "$path" + "\log\mailing.log" 



Function LogWrite
{
   Param ([heltring]$logstring)

   Add-content $Logfile -value $logstring
}

# Path & file name for msg body
$body=get-content ($path +"J040_COM_EST\ETU_MSG_EST_Comm.htm") | out-string


Clear-Host
if (!(test-path HKLM:\SYSTEM\CurrentControlSet\Services\Eventlog\Application\BRC))`
    {new-eventlog -Logname Application -source BRC `
    -ErrorAction SilentlyContinue}

# Path & file name for mailing list
$list=import-csv ($path + "J040_COM_EST\"+"J040_Mailing_List.csv")



$startTime = Get-date
$startLog = 'FSC Commission -' +$startTime



write-eventlog -logname Application -message $startlog -source BRC -ENTRYTYPE information -EventId 1 -category 0 

foreach ($i in $list)
{	
	if($i.flag -eq 1 -and $i.count -gt 0) {
		
		 
        if($i.attach1 ){
	        $attachments=@()
            $attach=@()
   
            $attachments += $i.attach1 

            $attach +=$i.attach1

           
          }
        if($i.attach2){
            $attachments=@()
            $attach=@()

            $attachments += $i.attach1 
            $attach +=$i.attach1
 
            $attachments += $i.attach2 
            $attach +=$i.attach2
            

        }
		
        if($i.attach3){

		
	    $attachments=@()
            $attach=@()


            $attachments += $i.attach1 
            $attach +=$i.attach1
	
            $attachments += $i.attach2 
            $attach +=$i.attach2
	
            $attachments += $i.attach3 
            $attach +=$i.attach3
           
         
        }                                           
        echo $attachments	

	    $params = @{}
	
	    $params['Attachments'] = $attachments
	
       	    $emailarray  = $I.EMAIL -split ','

        try{

      
		
	       send-mailmessage -smtpserver $smtp -to $emailarray -from "Commissions.Agent@henryschein.ca" -subject $i.subject -body $body -bodyashtml @params 

         
            write-eventlog -logname Application -message ( 'EST Commission -' +$startTime+ '  to  '  + $i.email + "    " + $attach ) -source BRC -ENTRYTYPE information -EventId 1 -category 0
           
         }
        catch
         {
             echo "sending message failed"
             write-eventlog -logname Application -message ('EST Commission -' +$startTime+ '  to  '  + $i.email + "   - Fail to send") -source BRC -ENTRYTYPe FailureAudit -EventId 2 -category 1

        }
 
    }

    elseif($i.flag -eq 1) {
    
        $emailarray  = $I.EMAIL -split ','
            try{
                send-mailmessage -smtpserver $smtp -to $emailarray  -from "Commissions.Agent@henryschein.ca" -subject $i.subject -body $body -bodyashtml 
                
                write-eventlog -logname Application -message ( 'EST Commission -' +$startTime+ '  to  '  + $i.email ) -source BRC -ENTRYTYPE information -EventId 1 -category 0
               
            }
            catch{
                    echo "sending message failed"
                   
                    write-eventlog -logname Application -message ('EST Commission -' +$startTime+ '  to  '  + $i.email + "   - Fail to send") -source BRC -ENTRYTYPe FailureAudit -EventId 2 -category 1
            }
      }
      else
       
      {
            echo "flag set to 0, no message sent"
      }
    

}


