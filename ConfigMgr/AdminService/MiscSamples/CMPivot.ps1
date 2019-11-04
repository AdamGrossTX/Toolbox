Param (
    [Parameter(Mandatory=$False)]
    $SiteServer
)

#$SiteServer = "CM01.ASD.NET"
#$SiteServer = "CMTP3-CM1.ASD.LAB"

$BaseUri = "https://$($SiteServer)/AdminService/v1.0/"
Write-hOst $BaseUri
$Query = "OperatingSystem"
$Params = @{
    Method = "Post"
    Uri = "$($BaseUri)/Collections('SMS00001')/AdminService.RunCmpivot"
    Body = @{"InputQuery"="$($Query)"} | ConvertTo-Json
    ContentType = "application/json"
    UseDefaultCredentials = $true
}

$Result = Invoke-RestMethod @Params

$Query = "OperatingSystem"
$Params = @{
    Method = "Post"
    Uri = "$($BaseUri)/Device(16777219)/AdminService.RunCMPivot"
    Body = @{"InputQuery"="$($Query)"} | ConvertTo-Json
    ContentType = "application/json"
    UseDefaultCredentials = $true
}

$Result = Invoke-RestMethod @Params

$OperationId = "72057594037928020"
$Params = @{
    Method = "Get"
    Uri = "$($BaseUri)/Device(16777219)/AdminService.CMPivotResult"
    #Body = @{"OperationId"= "$($OperationID)"} | ConvertTo-Json
    ContentType = "application/json"
    UseDefaultCredentials = $true
}

$Result = Invoke-RestMethod @Params