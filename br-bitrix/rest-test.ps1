
$url = "https://jsonplaceholder.typicode.com/posts"
$body = @{
   one = "foo"
   two  = "bar"
   three  = 1
}
Invoke-RestMethod -Method 'Post' -Uri $url -Body $body
