
#before using this mailer, two the following system environment variables need to be set up: 
	#BR_Mailing_Path: 	S:\Business Reporting\ZDEV_BR_Scripts\BRPoSh\BR_Mailer\
	#BR_Mailing_Server: 	usnymexhub1.us.hsi.local

$smtp=$env:BR_Mailing_Server

$path=$env:br_mailing_path  



#set up log file

$Logfile = "$path" + "\log\mailing.log" 

Function LogWrite
{
   Param ([string]$logstring)

   Add-content $Logfile -value $logstring
}



Clear-Host
if (!(test-path HKLM:\SYSTEM\CurrentControlSet\Services\Eventlog\Application\BRC))`
    {new-eventlog -Logname Application -source BRC `
    -ErrorAction SilentlyContinue}


#branch DS mailing list

$list=import-csv ("S:\Business Reporting\BR_Sales\Working\J011_Mailing_List.csv")

$startTime = Get-date
$startLog = 'Branch Daily Sales -' +$startTime
write-eventlog -logname Application -message $startlog -source BRC -ENTRYTYPE information -EventId 1 -category 0 


#get attachments, max 3 attachments
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
		
	        	send-mailmessage -smtpserver $smtp -to $emailarray -from "businessreporting.canada@henryschein.ca" -subject $i.subject -body $i.msg -bodyashtml -priority  high @params 
           
            		write-eventlog -logname Application -message ( 'Branch Daily Sales -' +$startTime+ '  to  '  + $i.email + "    " + $attach ) -source BRC -ENTRYTYPE information -EventId 1 -category 0
            
         	}
        	catch{
             		echo "sending message failed"
           
             		write-eventlog -logname Application -message ('Branch Daily Sales -' +$startTime+ '  to  '  + $i.email + "   - Fail to send") -source BRC -ENTRYTYPe FailureAudit -EventId 2 -category 1

        	}
 
    	}

    	elseif($i.flag -eq 1){
    
        	$emailarray  = $I.EMAIL -split ','
           	try{
                	send-mailmessage -smtpserver $smtp -to $emailarray  -from "businessreporting.canada@henryschein.ca" -subject $i.subject -body $i.msg -bodyashtml -priority  high                 
                	write-eventlog -logname Application -message ( 'Branch Daily Sales -' +$startTime+ '  to  '  + $i.email ) -source BRC -ENTRYTYPE information -EventId 1 -category 0
               
            	}
            	catch{
            		echo "sending message failed"
                	write-eventlog -logname Application -message ('Branch Daily Sales -' +$startTime+ '  to  '  + $i.email + "   - Fail to send") -source BRC -ENTRYTYPe FailureAudit -EventId 2 -category 1
            	}
      	}
      	else{

            echo "flag set to 0, no message sent"
    	}    
	
}


