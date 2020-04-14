Param(
    [int]$GraceSeconds = 5400, #Sets the max value for the timer - Default 90 mins
    [int]$FinalSeconds = 900 #Sets the time when Snooze stops working - Default 15 mins
)

#https://docs.microsoft.com/en-us/configmgr/develop/reference/core/clients/sdk/ccm_instanceevent-client-wmi-class
$NameSpace = "root\CCM\ClientSDK"
$ClassName = "CCM_ClientInternalUtilities"
$MethodName = "RaiseEvent"

$EpochTimeSeconds = ([DateTimeOffset](Get-Date)).ToUnixTimeSeconds()

$Class = $null
$TargetInstancePath = $null
$ActionType = [uint32]4 #RebootCountdonwStart
$UserSID = $null
$SessionID = $SessionID = [uint32]::MaxValue
$MessageLevel = [uint32]0
$Value = "{0}`t{1}`t{2}" -f $EpochTimeSeconds, $RestartEpochDateTimeSeconds, $GraceSeconds,$FinalSeconds
$Verbosity = [uint32]30

#region CIM
$CIMArgs = @{
    ClassName = $Class
    TargetInstancePath = $TargetInstancePath
    ActionType = $ActionType
    UserSID = $UserSID
    SessionID = $SessionID
    MessageLevel = $MessageLevel
    Value = $Value
    Verbosity = $Verbosity
}

Invoke-CimMethod -Namespace $NameSpace -ClassName $ClassName -MethodName $MethodName -Arguments $CIMArgs
