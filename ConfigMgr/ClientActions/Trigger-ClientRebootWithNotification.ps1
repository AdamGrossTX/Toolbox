
Param(
    [datetime]$CustomDateTime,
    [int]$Days,
    [int]$Hours,
    [int]$Minutes,
    [int]$Seconds,
    [int]$GraceSeconds = 5400,
    [int]$FinalSeconds = 900
)


If($CustomDateTime) {
    $RebootDateTime = $CustomDateTime
}
Else {
    $RebootTimeSpan = New-TimeSpan -Days $Days -Hours $Hours -Minutes $Minutes -Seconds $Seconds
    If($RebootTimeSpan.Seconds -eq 0) {
    $RebootDateTime = $(Get-Date) + $RebootTimeSpan
}
$RestartEpochDateTimeSeconds = ([DateTimeOffset]$RebootDateTime).ToUnixTimeSeconds()


#https://docs.microsoft.com/en-us/configmgr/develop/reference/core/clients/sdk/ccm_instanceevent-client-wmi-class
$NameSpace = "root\CCM\ClientSDK"
$ClassName = "CCM_ClientInternalUtilities"
$MethodName = "RaiseEvent"

$Class = $null
$TargetInstancePath = $null
$ActionType = [uint32]4 #RebootCountdonwStart
$UserSID = $null
$SessionID = $SessionID = [uint32]::MaxValue
$MessageLevel = [uint32]0
$Value = "{0}`t{1}`t{2}" -f $RestartEpochDateTimeSeconds, $GraceSeconds,$FinalSeconds
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
