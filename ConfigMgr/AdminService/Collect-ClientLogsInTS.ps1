Param (
    [Parameter(Mandatory=$False,HelpMessage="Enter your server name where AdminService is runnning (SMS Provider Role")]
    [string]$ServerName = "CMTP3-CM1",

    [Parameter(Mandatory=$false,HelpMessage="Enter the ResourceID of the target device")]
    [uint32[]]$TargetResourceIDs = 16777219,

    [Parameter(Mandatory=$false,HelpMessage="Enter a Collection ID that the target device is in")]
    [string]$TargetCollectionID = "SMS00001",
    [uint32]
    $Type=22

    )

[uint32]$RandomizationWindow = 1
[string]$MethodClass = "SMS_ClientOperation"
[string]$MethodName = "InitiateClientOperation"
[string]$ResultClass = "SMS_ClientOperationStatus"

$Type=22

$PostURL = "https://{0}/AdminService/wmi/{1}.{2}" -f $ServerName,$MethodClass,$MethodName
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

#Get Results
$GetURL = "https://{0}/AdminService/wmi/{1}" -f $ServerName,$ResultClass
(Invoke-RestMethod -Method Get -Uri "$($GetURL)" -UseDefaultCredentials).Value | Format-Table