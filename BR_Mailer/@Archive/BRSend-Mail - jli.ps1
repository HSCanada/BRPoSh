#Daily Sales Mailer

#before using this mailer, two the following system environment variables need to be set up: 
	#BR_Mailing_Path: 	S:\BR\zDev\BR_Scripts\BRPoSh\BR_Mailer\
	#BR_Mailing_Server: 	Usnymeht3.us.hsi.local 

#on moving to window 10, need to set new script execution policy using ADMIN on Windows Powershell ISE: Set-ExecutionPolicy unrestricted
#need to register: BRC for event log ( regedit: local maching: HKLM:\SYSTEM\CurrentControlSet\Services\Eventlog\application\BRC)


$smtp=$env:BR_Mailing_Server

$path=$env:br_mailing_path  



#set up log file

$Logfile = "$path" + "\log\mailingds.log" 

#Add-Content -Path C:\Temp\Log. txt -Value "This is a new line of text."

Function LogWrite
{
   Param ([string]$logstring)

   Add-content $Logfile -value $logstring
}



Clear-Host
if (!(test-path HKLM:\SYSTEM\CurrentControlSet\Services\Eventlog\application\BRC))`
    {new-eventlog -Logname Application -source BRC `  #{new-eventlog -Logname Application -source BRC `
    -ErrorAction SilentlyContinue}


#branch DS mailing list

$list=import-csv ("S:\BR\BR_Sales\Working\J011_Mailing_List.csv")

$startTime = Get-date
$startLog = 'Branch Daily Sales -' +$startTime
write-eventlog -logname Application -message $startlog -source BRC -ENTRYTYPE information -EventId 1 -category 0 
 #Add-content $Logfile -value "$startLog


     
Add-content $Logfile -value ('   When        |                What            |               Subject                |               Receipt            |       Status     ')  

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
            #Add-content $Logfile -value "When     What       Subject        Receipt       Status"
            Add-content $Logfile -value ( '' + $startTime + '|' + $attach  + '|' + $i.subject + '|' + $i.email + '|' + 'Success' )
            
         	}
        	catch{
             		echo "sending message failed"
           
             		write-eventlog -logname Application -message ('Branch Daily Sales -' +$startTime+ '  to  '  + $i.email + "   - Fail to send") -source BRC -ENTRYTYPe FailureAudit -EventId 2 -category 1
              Add-content $Logfile -value ( '' + $startTime + '|' + $attach  + '|' + $i.subject + '|' + $i.email + '|' + 'Failed' )


        	}
 
    	}

    	elseif($i.count -eq 0){
    
        	$emailarray  = $I.EMAIL -split ','
           	try{
                	send-mailmessage -smtpserver $smtp -to $emailarray  -from "businessreporting.canada@henryschein.ca" -subject $i.subject -body $i.msg -bodyashtml -priority  high                 
                	write-eventlog -logname Application -message ( 'Branch Daily Sales -' +$startTime+ '  to  '  + $i.email ) -source BRC -ENTRYTYPE information -EventId 1 -category 0
                #Add-content $Logfile -value ('Branch Daily Sales -'+ $startTime + $i.email)
               # Add-content $Logfile -value ( '' + $startTime + '|' + $attach  + '|' + $i.subject + '|' + $i.email + '|' + 'Success' )
                Add-content $Logfile -value ( '' + $startTime + '|' + 'No attachment' + '|' + 'Total Sales' + '|' + $i.email + '|' + 'Success' )

               
            	}
            	catch{
            		echo "sending message failed"
                	write-eventlog -logname Application -message ('Branch Daily Sales -' +$startTime+ '  to  '  + $i.email + "   - Fail to send") -source BRC -ENTRYTYPe FailureAudit -EventId 2 -category 1
                # Add-content $Logfile -value ('Branch Daily Sales -' + $startTime + $i.email + ' - Fail to send')
                  Add-content $Logfile -value ( '' + $startTime + '|' + $attach  + '|' + $i.subject + '|' + $i.email + '|' + 'Failed' )

            	}
      	}
     	else{

            echo "flag set to 0, no message sent"
         Add-content $Logfile -value ( '' + $startTime + '|' + 'No attachment' + '|' + 'Total Sales' + '|' + $i.email + '|' + 'Success' )
       }    
	
}


