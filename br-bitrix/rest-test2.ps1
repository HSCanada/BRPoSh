<#
$url = "https://jsonplaceholder.typicode.com/posts"
$body = @{
   title = "foo"
   body = "bar"
   userId = 1
}
#>

param(
    [parameter(
        Mandatory         = $true,
        ValueFromPipeline = $true)]
    $pipelineInput
)

Invoke-RestMethod -Method 'Post' -Uri $url -Body $pipelineInput
#Invoke-RestMethod -Method 'Post' -Uri $url -Body $body
