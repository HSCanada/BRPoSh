# Send Service Email
# 12 Nov 18

$smtp=$env:BR_Mailing_Server

$path=$env:br_mailing_path

$path=$path + 'service\'
$body = ''

#debug
echo $smtp
echo $path

# Path & file name for mailing list
$list=import-csv ($path + 'Service_Mailing_List.csv')

# Path & file name for msg body
$body=get-content ($path +'Email.Msg.Body\Service - Mail Body3.htm') | out-string


$startTime = Get-date
$startLog = 'Service-' +$startTime

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
		
	       send-mailmessage -smtpserver $smtp -to $emailarray -from "businessreporting.canada@henryschein.ca" -subject $i.subject -body $body -bodyashtml @params 

          
         }
        catch
         {
             echo "sending message failed"

        }
 
    }

    elseif($i.flag -eq 1) {
    
        $emailarray  = $I.EMAIL -split ','
            try{

                #Write-Host $body
                send-mailmessage -smtpserver $smtp -to $emailarray  -from "businessreporting.canada@henryschein.ca" -subject $i.subject -body $body -bodyashtml 
                
              
            }
            catch{
                    echo "sending message failed"
                   
            }
      }
      else
       
      {
             try{
                send-mailmessage -smtpserver $smtp -to $emailarray  -from "businessreporting.canada@henryschein.ca" -subject $i.subject -body $body -bodyashtml 
                
               
            }
            catch{
                    echo "sending message failed"
                   
            }
      }
    

}

