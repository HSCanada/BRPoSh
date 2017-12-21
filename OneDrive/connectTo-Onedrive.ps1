Import-Module "C:\Program Files\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell" -DisableNameChecking

#import-module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking; 

Function Invoke-RestSPO(){
 
Param(
[Parameter(Mandatory=$True)]
[String]$Url,

[Parameter(Mandatory=$False)]
[Microsoft.PowerShell.Commands.WebRequestMethod]$Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,
 
[Parameter(Mandatory=$True)]
[String]$UserName,
 
[Parameter(Mandatory=$True)]
[String]$Password,
 
[Parameter(Mandatory=$False)]
[String]$Metadata,

[Parameter(Mandatory=$False)]
[String]$RequestDigest,

[Parameter(Mandatory=$False)]
[System.Byte[]]$Body,
 
[Parameter(Mandatory=$False)]
[String]$ETag,
 
[Parameter(Mandatory=$False)]
[String]$XHTTPMethod,

[Parameter(Mandatory=$False)]
[System.String]$Accept = "application/json;odata=verbose",

[Parameter(Mandatory=$False)]
[String]$ContentType = "application/json;odata=verbose",

[Parameter(Mandatory=$False)]
[Boolean]$BinaryStringResponseBody = $False

)

   $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
 
   $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $SecurePassword)

   #[net.httpWebRequest] $request = [System.Net.WebRequest]::Create($Url)
    [net.httpWebRequest] $request = [System.Net.WebRequest]::Create("https://henryscheininc-my.sharepoint.com")

   $request.Credentials = $credentials
   $request.Headers.Add("X-FORMS_BASED_AUTH_ACCEPTED", "f")
   $request.ContentType = $ContentType
   $request.Accept = $Accept
   #$refererurl="https://YOUR_COMPANY_NAME-my.sharepoint.com/personal/YOUR_AREA_NAME/_layouts/15/onedrive.aspx"

   $refererurl="https://henryscheininc-my.sharepoint.com/personal/opportunitiesnow_henryschein_ca/_layouts/15/start.aspx"

   $request.Referer = $refererurl
   
   $request.Method=$Method

 
   if($RequestDigest) { 
      $request.Headers.Add("X-RequestDigest", $RequestDigest)
   }
   if($ETag) { 
      $request.Headers.Add("If-Match", $ETag)
   }
   if($XHTTPMethod) { 
      $request.Headers.Add("X-HTTP-Method", $XHTTPMethod)
   }
   if($Metadata -or $Body) {
      if($Metadata) {     
         $Body = [byte[]][char[]]$Metadata
      }      

      $request.ContentLength = $Body.Length
      
      $stream = $request.GetRequestStream()
      $stream.Write($Body, 0, $Body.Length)
      
      
   }
   else {
      $request.ContentLength = 0
   }

   $response = $request.GetResponse()

   try {
       if($BinaryStringResponseBody -eq $False) {    
           $streamReader = New-Object System.IO.StreamReader $response.GetResponseStream()
           try {
              $data=$streamReader.ReadToEnd()
              #$data
              $results = $data | ConvertFrom-Json
              $RequestDigest=$results.d.GetContextWebInformation.FormDigestValue
              #$results.d
              return $RequestDigest
           }
           finally {
              $streamReader.Dispose()
           }
        }
        else {
           $dataStream = New-Object System.IO.MemoryStream
           try {
           Stream-CopyTo -Source $response.GetResponseStream() -Destination $dataStream
           $dataStream.ToArray()
           }
           finally {
              $dataStream.Dispose()
           } 
        }
    }
    finally {
        $response.Dispose()
        
    }
   
}
 
# Get Context Info  
Function Get-SPOContextInfo(){ 
  
Param( 
 [Parameter(Mandatory=$True)] 
 [String]$WebUrl, 
   
 [Parameter(Mandatory=$True)] 
 [String]$UserName, 
   
 [Parameter(Mandatory=$True)] 
 [String]$Password 
 )  
    
    $Url = $WebUrl + "/_api/contextinfo" 

    Invoke-RestSPO $Url Post $UserName $Password
} 


Function Set-OnedrivePermission(){
 
Param(
[Parameter(Mandatory=$True)]
[String]$File,
 
[Parameter(Mandatory=$True)]
[String]$Email,
 
[Parameter(Mandatory=$True)]
[String]$Permission,

[Parameter(Mandatory=$True)]
[String]$RequestDigest,

[Parameter(Mandatory=$True)]
[String]$WebUrl,

[Parameter(Mandatory=$True)]
[String]$Username,

[Parameter(Mandatory=$True)]
[String]$Password
)
 
   
   #Create the Metadata
   $PermissionCode="0"
   if($Permission -eq "Write"){
     $PermissionCode="2"
   }
    if($Permission -eq "Read"){
     $PermissionCode="1"
   }
    if($Permission -eq "Remove"){
     $PermissionCode="0"
   }
  
   $Metadata = "{'resourceAddress':'$weburl/Documents/$File','userRoleAssignments':[{'UserId':'i:0#.f|membership|$email','Role':$PermissionCode}],'validateExistingPermissions':false,'additiveMode':false,'sendServerManagedNotification':false,'customMessage':null,'includeAnonymousLinksInNotification':false,'propagateAcl':false}"

   $Url=$WebUrl+"/_api/SP.Sharing.DocumentSharingManager.UpdateDocumentSharingInfo"
   $Metadata
   Invoke-RestSPO $Url POST $UserName $Password $Metadata $RequestDigest
}
 

Function Stream-CopyTo([System.IO.Stream]$Source, [System.IO.Stream]$Destination)
{
    $buffer = New-Object Byte[] 8192 
    $bytesRead = 0
    while (($bytesRead = $Source.Read($buffer, 0, $buffer.Length)) -gt 0)
    {
         $Destination.Write($buffer, 0, $bytesRead)
    }
}

#Should be improved to hide account data!
#$WebUrl = "https://YOUR_COMPANY_NAME-my.sharepoint.com/personal/YOUR_AREA_NAME"
#$WebUrl ="https://henryscheininc-my.sharepoint.com/personal/opportunitiesnow_henryschein_ca/_layouts/15/start.aspx#/Documents/Forms/All.aspx

#$WebUrl = "https://henryscheininc-my.sharepoint.com/personal/opportunitiesnow_henryschein_ca"
$WebUrl = "https://www.google.ca/"  #https://henryscheininc-my.sharepoint.com/personal/opportunitiesnow_henryschein_ca"
$webUrl ="henryscheininc-my.sharepoint.com"

 #/_layouts/15"  #/guestaccess.aspx?folderid=1cd98a2a442f248389de58469d4577e39&authkey=ARiiLXEP11uweTSaK9VXqo8"


#$Username="USERNAME"
#$Password="PASSWORD"

#$Username="OpportunitiesNow@henryschein.ca" #OpportunitiesNow@henryschein.ca"
#$Password="EatMyPassword1"

$Username=""
$Password=""



#$RequestDigest=Get-SPOContextInfo -UserName $Username -Password $Password -WebUrl $WebUrl
$RequestDigest=Get-SPOContextInfo  -WebUrl $WebUrl



Set-OnedrivePermission -RequestDigest $RequestDigest -File "DIR/FILENAME" -Email "EMAILACCOUNT OF THE USER" -Permission "READ or WRITE or REMOVE" -Username $Username -Password $Password -WebUrl $WebUrl