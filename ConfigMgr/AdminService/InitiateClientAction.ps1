#region Change to your info###
$ServerName = "CMTP3-CM1.asd.lab"
$SiteCode = "TP3"
$NameSpace = "root\SMS\Site_{0}" -f $SiteCode
$ClassName = "SMS_ClientOperation"
$MethodName = "InitiateClientOperation"

[string]$TargetCollectionID = "TP300018"
[uint32]$Type = 8
[uint32]$RandomizationWindow = 1
[uint32[]]$TargetResourceIDs = 16777223
###Endregion###

$Types = @{
    "DownloadComputerPolicy" = 8
    "DownloadUserPolicy" = 9
    "CollectDiscoveryData" = 10
    "CollectSoftwareInventory" = 11
    "CollectHardwareInventory" = 12
    "EvaluateApplicationDeployments" = 13
    "EvaluateSoftwareUpdateDeployments" = 14
    "SwitchToNextSoftwareUpdatePoint" = 15
    "EvaluateDeviceHealthAttestation" = 16
    "CheckConditionalAccessCompliance" = 125
    "WakeUp" = 150
    "Restart" = 17
    "EnableVerboseLogging" = 20
    "DisableVerboseLogging" = 21
}

$Type = $Types.Keys | ForEach-Object {Write-Host $Types[$_] : $_}
$Type = Read-Host -Prompt "Which client action?"

#region CIM
$Args = @{
    TargetCollectionID = $TargetCollectionID
    Type = $Type
    RandomizationWindow = $RandomizationWindow
    TargetResourceIDs = $TargetResourceIDs
}
Invoke-CimMethod -Namespace $NameSpace -ClassName $ClassName -MethodName $MethodName -Arguments $Args | Select-Object ReturnValue
Get-CimInstance -Namespace $NameSpace -ClassName $ClassName | Format-Table
#endregion


#region AdminService 1910 TP
$PostURL = "https://{0}/AdminService/wmi/{1}.{2}" -f $ServerName,$ClassName,$MethodName
$Headers = @{
    "Content-Type" = "Application/json"
}
$Body = @{
    TargetCollectionID = $TargetCollectionID
    Type = $Type
    RandomizationWindow = $RandomizationWindow
    TargetResourceIDs = $TargetResourceIDs
} | ConvertTo-Json
    
Invoke-RestMethod -Method Post -Uri "$($PostURL)" -Body $Body -Headers $Headers -UseDefaultCredentials | Select-Object ReturnValue

$GetURL = "https://{0}/AdminService/wmi/{1}" -f $ServerName,$ClassName
(Invoke-RestMethod -Method Get -Uri "$($GetURL)" -UseDefaultCredentials).Value | Format-Table

#end region