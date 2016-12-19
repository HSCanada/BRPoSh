Import-Module ActiveDirectory

$SMTPServer=”USNYMEXHUB1”
$ExpiresInDays = 14
$FromIT = “HelpDesk@henryschein.ca"
$ToIT = "DLHSCNational-IT@henryschein.ca"
$MaxPasswordAgeTimeSpan = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge

Get-ADUser -filter * -Properties PasswordNeverExpires, PasswordExpired, EmailAddress, PasswordLastSet, GivenName |where {$_.Enabled -eq “True”} | where { $_.PasswordNeverExpires -eq $false } | where { $_.passwordexpired -eq $false } | foreach {

$EmailAddr = $_.EmailAddress
$FirstName = $_.GivenName
$Today = (get-date)

if (!$_.PasswordExpired -and !$_.PasswordNeverExpires) {
 
        $ExpiryDate=$_.PasswordLastSet + $maxPasswordAgeTimeSpan
        $DaysLeft=($ExpiryDate-$today).days
 
        if ($DaysLeft -lt $ExpiresInDays -and $DaysLeft -gt 0) {


            $Subject="$FirstName, your Henry Schein email password expires on $ExpiryDate (in $DaysLeft days)"
            $Body =”
                <p> 
                <font color=""black"" face=""Calibri"" size=""3"">

                $FirstName,<br><br>

                *NOTE* If you are an <u>internal</u> office user (currently connected to the office network), then press <b>CTRL-ALT-DEL</b><br>
				and select <b>Change a Password</b>, then logoff your computer and back on for the change to take effect.<br><br>
				
				Otherwise, please follow the steps below:<br><br>

                1. Login to Henry Schein webmail at https://email.henryschein.com<br>
                2. Click on <b>Options</b> (upper right of your screen)<br>
                3. Click on <b>Change Password</b> (left panel of your screen)<br>
                4. Enter your old password and new password as prompted and click <b>Save</b> (upper left of your screen)<br><br>
                
                *NOTE*  Your Username is: $EmailAddr<br><br>
                
                <b><u>PASSWORD GUIDELINES:</u></b><br><br>
                
                All passwords must be a minimum of 8 characters and must follow these parameters:<br><br>
                
                - Must NOT be a previously used password<br>
                - Must NOT contain your first or last name<br>
                - Must contain English uppercase characters (A through Z)<br>
                - Must contain English lowercase characters (a through z)<br>
                - Must contain at least one digit (0 through 9) or non-alphabetic character (such as !, $, #, %)<br><br>

                If you have any questions, please reply to this email or call the IT Helpdesk @ 1-888-722-2077.<br><br>
                
                Thank you.
                </P>”

                ForEach ($Email in $_.EmailAddress) {  
                    
                    #Send-MailMessage -to $Email -Cc $ToIT,jason.stauffer@henryschein.ca -from $FromIT -subject $Subject -body $Body -smtpserver $SMTPServer -BodyAsHtml -priority High
					Send-MailMessage -to $Email -Cc jason.stauffer@henryschein.ca -from $FromIT -subject $Subject -body $Body -smtpserver $SMTPServer -BodyAsHtml -priority High
                    #Send-MailMessage -to jason.stauffer@henryschein.ca -Cc jason.stauffer@henryschein.ca -from $FromIT -subject $Subject -body $Body -smtpserver $SMTPServer -BodyAsHtml -priority High
                }
            }
        }
}
