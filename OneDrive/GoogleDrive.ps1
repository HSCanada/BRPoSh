


#################################################################

#https://portal.office.com/adminportal/home (error: You don’t have permission to access this page or perform this action) with opportunitiesnow

$OAuth ="474461130529-gs4kiqrsl32rvbinpa9ufvdq6g6f8lse.apps.googleusercontent.com" #OAuth Client Id
$secret ="VxQw4zVfFOnX0GnNNfAAMy5R"  #Clien Secret"

$redirectURL = "https://developers.google.com/oauthplayground/ REDIRECT url"


#google drive

#$oauth_json = '{"web":{"client_id":"10649365436h34234f34hhqd423478fsdfdo.apps.googleusercontent.com",
# "client_secret":"h78H78h7*H78h87",
# "redirect_uris":["https://developers.google.com/oauthplayground"]}}' | ConvertFrom-Json


$oauth_json = '{"web":{"client_id":"474461130529-gs4kiqrsl32rvbinpa9ufvdq6g6f8lse.apps.googleusercontent.com", "client_secret":"VxQw4zVfFOnX0GnNNfAAMy5R", "redirect_uris":["https://developers.google.com/oauthplayground"]}}' | ConvertFrom-Json


 $code = Request-GDriveAuthorizationCode -ClientID $oauth_json.web.client_id -ClientSecret $oauth_json.web.client_secret

  $refresh = Request-GDriveRefreshToken -ClientID $oauth_json.web.client_id -ClientSecret $oauth_json.web.client_secret -AuthorizationCode $code

  $access = Get-GDriveAccessToken -ClientID $oauth_json.web.client_id   -ClientSecret $oauth_json.web.client_secret   -RefreshToken $refresh.refresh_token

  # Upload new file
Add-GDriveItem -AccessToken $access.access_token -InFile c:\SomeDoc.doc -Name SomeDocument.doc

