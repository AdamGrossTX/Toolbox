param (
    $incoming,
    $DeviceName = "Intel® Smart Sound Technology for USB Audio",
    [switch]$Remediate = $false
)
try {
    $Devices = Get-PnpDevice -FriendlyName $DeviceName -ErrorAction SilentlyContinue
    $Disabled = $true
    foreach($Device in $Devices) {
        if($Device.Problem -ne 'CM_PROB_DISABLED' -and $Device.Problem -ne 'CM_PROB_PHANTOM') {
            $Disabled = $false
            if($Remediate.IsPresent) {
                $Device | Disable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
                Get-PnpDevice -InstanceId $Device.InstanceId -ErrorAction SilentlyContinue
            }
        }
    }
    if(-not $Remediate) {
        return $Disabled
    }
}
catch {
    throw $_
}
