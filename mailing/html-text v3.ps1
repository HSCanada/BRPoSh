$smtp="usnymexhub1.us.hsi.local"
$list=import-csv .\"mailing list.csv"
$path=(get-location) 
foreach ($i in $list)
{	
	if($i.count -gt 0) {
		
		 
if($i.attach1 ){
	$attachments=@()
  		$attachments +="$path" + "\attach\" + $i.attach1 }
if($i.attach2){
$attachments=@()
		$attachments += "$path" + "\attach\" +$i.attach1 
		$attachments += "$path" + "\attach\" + $i.attach2 }

		
if($i.attach3){

		
		$attachments=@()
		$attachments += "$path" + "\attach\" +$i.attach1 
		$attachments += "$path" + "\attach\" + $i.attach2 
		$attachments += "$path" + "\attach\" + $i.attach3 }


	echo $attachments

	$params = @{}
	
	$params['Attachments'] = $attachments	
		
	send-mailmessage -smtpserver $smtp -to $i.email -from "businessreporting.canada@henryschein.ca" -subject $i.subject -body $i.msg -bodyashtml -priority  high @params #-attachments "S:\Business Reporting\Jennifer\Project\script\attach\201602_AZ1CI_Top15.pdf" 
 #@params
	}
else {
send-mailmessage -smtpserver $smtp -to $i.email -from "businessreporting.canada@henryschein.ca" -subject $i.subject -body $i.msg -bodyashtml -priority high
}

}
