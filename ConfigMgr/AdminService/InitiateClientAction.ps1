<#
    www.github.com/AdamGrossTX
    twitter.com/AdamGrossTX
    asquaredozen.com
    note: this script could be optimized but is broken up to make it easy to read and step through for learning how AdminService works.
#>
[cmdletbinding()]
Param (
    [Parameter(HelpMessage="Enter your server name where AdminService is runnning (SMS Provider Role")]
    [string]$ServerName = "CPRTHQ-CCM01.CPCHEM.NET",

    [Parameter(HelpMessage="Enter the ResourceID of the target device")]
    [uint32[]]$TargetResourceIDs = '16860287',

    [Parameter(HelpMessage="Enter a Collection ID that the target device is in")]
    [string]$TargetCollectionID = "SMS00001"
)

$Types = [Ordered]@{
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
    "CollectClientLogs" = 22
}

[uint32]$RandomizationWindow = 1
[string]$MethodClass = "SMS_ClientOperation"
[string]$MethodName = "InitiateClientOperation"
[string]$ResultClass = "SMS_ClientOperationStatus"

$Types.Keys | ForEach-Object {Write-Host $Types[$_] : $_}
[uint32]$Type = Read-Host -Prompt "Which client action?"

$BaseUri = "https://$($ServerName)/AdminService/wmi/"
Write-Host $BaseUri

$PostURL = "$($BaseUri)$($MethodClass).$($MethodName)"
$Headers = @{
    "Content-Type" = "Application/json"
}
$Body = @{
    TargetCollectionID = $TargetCollectionID
    Type = $Type
    RandomizationWindow = $RandomizationWindow
    TargetResourceIDs = $TargetResourceIDs
} | ConvertTo-Json

$Result = Invoke-RestMethod -Method Post -Uri $PostURL -Body $Body -Headers $Headers -UseDefaultCredentials | Select-Object ReturnValue

$Result

#Get Results
#start-sleep -Seconds 30

#$GetURL = "$($BaseUri)$($ResultClass)"
#$Results = Invoke-RestMethod -Method Get -Uri $GetURL -UseDefaultCredentials
#$Results.Value | Format-Table