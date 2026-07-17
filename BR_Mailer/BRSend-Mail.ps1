#Daily Sales Mailer
# tmc, 10 Jul 26, fix env and logging for genpact 

#before using this mailer, two the following system environment variables need to be set up: 
	#BR_Mailing_Path: 	S:\BR\zDev\BR_Scripts\BRPoSh\BR_Mailer\
	#BR_Mailing_Server: 	Usnymeht3.us.hsi.local 

#on moving to window 10, need to set new script execution policy using ADMIN on Windows Powershell ISE: Set-ExecutionPolicy unrestricted

$smtp=$env:BR_Mailing_Server
$path=$env:br_mailing_path  
$Logfile = "$path" + "\log\mailing.log" 

Function LogWrite
{
   Param ([string]$logstring)

    Add-Content -Path $Logfile -Value "`n$logstring" -Force
    Write-Host $logstring -ForegroundColor Green
}



Clear-Host

#branch DS mailing list

$list=import-csv ("S:\BR\BR_Sales\Working\J011_Mailing_List.csv")

$startTime = Get-date
$startLog = 'Branch Daily Sales -' +$startTime + ' start'
# write-eventlog -logname Application -message $startlog -source BRC -ENTRYTYPE information -EventId 1 -category 0 
LogWrite $startlog


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
            LogWrite ( 'Branch Daily Sales -' +$currTime+ '  attachments = '  + $attachments)

	

		$params = @{}	
		$params['Attachments'] = $attachments

	
        	$emailarray  = $I.EMAIL -split ','
            $currTime = Get-date

        	try{
		
	        	send-mailmessage -smtpserver $smtp -to $emailarray -from "businessreporting.canada@henryschein.ca" -subject $i.subject -body $i.msg -bodyashtml -priority  high @params 
                LogWrite ( 'Branch Daily Sales -' +$currTime+ '  to  '  + $i.email + "    " + $attach )
            
         	}
        	catch{
                LogWrite ( 'Branch Daily Sales -' +$currTime+ '  to  '  + $i.email + "   - Fail to send")
        	}
 
    	}

    	elseif($i.flag -eq 1){
    
        	$emailarray  = $I.EMAIL -split ','
            $currTime = Get-date

           	try{
                	send-mailmessage -smtpserver $smtp -to $emailarray  -from "businessreporting.canada@henryschein.ca" -subject $i.subject -body $i.msg -bodyashtml -priority  high                 
                    LogWrite ( 'Branch Daily Sales -' +$currTime+ '  to  '  + $i.email )
               
            	}
            	catch{
                    LogWrite ( 'Branch Daily Sales -' +$currTime+ '  to  '  + $i.email + "   - Fail to send")

            	}
      	}
      	else{
            $currTime = Get-date

            LogWrite ( 'Branch Daily Sales -' +$currTime+ "flag set to 0, no message sent")
    	}    
	
}


# LogWrite
LogWrite ( "Done.")

# temp pause for debugger
Pause

