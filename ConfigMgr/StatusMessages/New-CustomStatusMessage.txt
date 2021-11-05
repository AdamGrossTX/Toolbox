
#Usage
#New-CustomStatusMessage.ps1 -Component GenericMsg_SeeInsertionStrings -InsStr1 MsgType_Office365Upgrade -InsStr2 projectInstalled
#New-CustomStatusMessage.ps1 GenericMsg_SeeInsertionStrings MsgType_Office365Upgrade projectInstalled

<#
SELECT 
	* 
FROM 
	v_StatMsgWithInsStrings 
WHERE 
    messageid = 39997
#>

Param (
    [Parameter(Position=0)]
    [string]$Component = "GenericMsg_SeeInsertionStrings",

    [Parameter(Position=1)]
    [string]$InsStr1 = "MsgType_Office365Upgrade",

    [Parameter(Position=2)]
    [string]$InsStr2 = "projectInstalled",

    [Parameter(Position=3)]
    [string]$InsStr3,

    [Parameter(Position=4)]
    [string]$InsStr4,

    [Parameter(Position=5)]
    [string]$InsStr5,

    [Parameter(Position=6)]
    [string]$InsStr6,

    [Parameter(Position=7)]
    [string]$InsStr7,

    [Parameter(Position=8)]
    [string]$InsStr8,

    [Parameter(Position=9)]
    [string]$InsStr9,

    [Parameter(Position=10)]
    [string]$InsStr10

)

$PropertyList = @{
    "Attribute403" = $Component
    "InsertionString1" = $InsStr1
    "InsertionString2" = $InsStr2
    "InsertionString3" = $InsStr3
    "InsertionString4" = $InsStr4
    "InsertionString5" = $InsStr5
    "InsertionString6" = $InsStr6
    "InsertionString7" = $InsStr7
    "InsertionString8" = $InsStr8
    "InsertionString9" = $InsStr9
    "InsertionString10" = $InsStr10
}

Try {
    $eventObj = New-Object -ComObject Microsoft.SMS.Event -ErrorAction Stop
    $eventObj.EventType = "SMS_GenericStatusMessage_Info"
    ForEach($Key in $PropertyList.Keys) {
        If($null -ne $PropertyList[$Key]) {
            $eventObj.SetProperty($Key, $PropertyList[$Key])
        }
    }
    $eventObj.Submit()
    Return 0
}
Catch {
    Write-Error $Error[0]
    Return -1
}


<#
#Simple Version

Try {
    $eventObj = New-Object -ComObject Microsoft.SMS.Event -ErrorAction Stop
    $eventObj.EventType = "SMS_GenericStatusMessage_Info"
    $eventObj.SetProperty("Attribute403", "GenericMsg_SeeInsertionStrings");
    $eventObj.SetProperty("InsertionString1", "MsgType_Office365Upgrade")
    $eventObj.SetProperty("InsertionString2", "projectInstalled")
    $eventObj.Submit() 
    Return 0
}
Catch {
    Write-Error $Error[0]
    Return -1
}
#>