Param (
    [Parameter(Mandatory=$True)]
    $SiteServer = "CM01.ASD.NET"
)

$BaseUri = "https://$($SiteServer)/AdminService/v1.0/"
Write-hOst $BaseUri
$Query = "OperatingSystem"
$Params = @{
    Method = "Post"
    Uri = "$($BaseUri)/Collections('PS100060')/AdminService.RunCmpivot"
    Body = @{"InputQuery"="$($Query)"} | ConvertTo-Json
    ContentType = "application/json"
    UseDefaultCredentials = $true
}

$Result = Invoke-RestMethod @Params