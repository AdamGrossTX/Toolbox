Param (
    [switch]$CreateNewContext=$True
)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Install-Module Az
Import-Module Az
Login-AzAccount
#region Get Upgrade Analytics Data
If($CreateNewContext.IsPresent) {
    Login-AzAccount
    Save-AzContext -Path "$($PSScriptRoot)\azprofile.json" -Force
}
Import-AzContext -Path "$($PSScriptRoot)\azprofile.json" -ErrorAction Stop

$SiteServer = "cmtp3-cm1.asd.lab"
$BaseUri = "https://$($SiteServer)/AdminService/v1.0/"

$Query = "OS"
$Params = @{
    Method = "Post"
    Uri = "$($BaseUri)Collections('SMS00001')/AdminService.RunCmpivot"
    Body = @{"InputQuery"="$($Query)"} | ConvertTo-Json
    ContentType = "application/json"
    UseDefaultCredentials = $true
}
$Result = Invoke-RestMethod @Params

<#
$Params = @{
    Method = "Get"
    Uri = "$($BaseUri)Collections"
    UseDefaultCredentials = $true
    UseBasicParsing = $true
    Headers = @{ACCEPT="application/json"}
}

$Result = Invoke-RestMethod @Params -Verbose

Invoke-RestMethod ""
#>