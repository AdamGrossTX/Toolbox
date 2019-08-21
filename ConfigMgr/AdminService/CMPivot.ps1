Param (
    $SiteServer = "CMTP3-CM1.ASD.LAB"
)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$BaseUri = "https://$($SiteServer)/AdmiinService/v1.0/"

$Query = "OperatingSystem"

$Params = @{
    Method = "Post"
    Uri = "$($BaseUri)/Collections('SMS00001')/AdminService.RunCmpivot"
    Body = @{"InputQuery"="$($Query)"} | ConvertTo-Json
    ContentType = "application/json"
    UseDefaultCredentials = $true
}

$Result = Invoke-RestMethod @Params