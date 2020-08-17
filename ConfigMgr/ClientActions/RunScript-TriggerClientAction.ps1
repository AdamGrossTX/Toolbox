Param(
$strAction = "{00000000-0000-0000-0000-000000000001}"
)

Get-WmiObject -Namespace "root\ccm\invagt" -Class InventoryActionStatus | where {$_.InventoryActionID -eq "$($strAction)"} | Remove-WmiObject

try {
    Invoke-WmiMethod -Namespace root\ccm -Class SMS_Client -Name TriggerSchedule -ArgumentList $strAction -ErrorAction Stop | Out-Null
    Return 0
}
catch {
    Return $Error[0]
}