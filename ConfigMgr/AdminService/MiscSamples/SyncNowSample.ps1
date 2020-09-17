<#
    www.github.com/AdamGrossTX
    twitter.com/AdamGrossTX
    asquaredozen.com
    note: this script could be optimized but is broken up to make it easy to read and step through for learning how AdminService works.

    #Doesn't work. Some issue with SQL.
    Check the DM_GetSyncNowStatus Stored Proc in SQL.

#>
[cmdletbinding()]
Param (
    [string]
    $SiteServer,
    
    [string]
    $DeviceName
)

$SiteServer = "CM01.ASD.NET"
$DeviceName ="ASD-50124588"

[string]$MethodClass = "SMS_DeviceMethods"
[string]$MethodName = "SyncNow"

$BaseUri = "https://$($SiteServer)/AdminService/wmi/"
Write-Host $BaseUri

$ClassName = "SMS_R_System"
$GetDeviceParams = @{
    Method = "Get"
    Uri = "$($BaseUri)$($ClassName)?`$filter=Name eq `'$($DeviceName)`'"
    ContentType = "application/json"
    UseDefaultCredentials = $true
}

$Device = Invoke-RestMethod @GetDeviceParams
[uint32]$ResourceId = $Device.Value.ResourceId

$MethodParams = @{
    Method = "Post"
    Uri = "$($BaseUri)$($MethodClass).$($MethodName)"
    ContentType = "application/json"
    UseDefaultCredentials = $true
}
$Body = @{ResourceId = $ResourceId} | ConvertTo-Json
$Result = Invoke-RestMethod @MethodParams -Body $Body | Select-Object ReturnValue