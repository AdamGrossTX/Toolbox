
<#
.DESCRIPTION
    attempts to check for pending reboots based on Feature Updates or Quality Updates and provides a reboot date/time using the WUFB Grace Period settings configured on the device.
    Deploy as the detection script in a proactive remediation script in Intune then export the results for easy reporting.

.NOTES
    Author: Adam Gross - @AdamGrossTX
    GitHub: https://github.com/AdamGrossTX
#>

try {
    $QURegistryKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"LocalMachine", $Computer) 
    $QURegistrySubKey = $QURegistryKey.OpenSubKey(" ") 
    if ($QURegistrySubKey) {
        $QURegistrySubKeyNames = $QURegistrySubKey.GetSubKeyNames() 
        $QURebootRequired = $QURegistrySubKeyNames -contains "RebootRequired" 
    }
    
    $FURegistryKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"LocalMachine", $Computer) 
    $FURegistrySubKey = $FURegistryKey.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\CommitRequired") 
    if($FURegistrySubKey) {
        $FURegistrySubKeyNames = if ($FURegistrySubKey) { $FURegistrySubKey.GetSubKeyNames() }
    }
    
    foreach ($Key in $FURegistrySubKeyNames) {
        $FUGUIDS = (Get-Item -Path registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\CommitRequired\$($Key)" -ErrorAction SilentlyContinue).GetValueNames()
        $FUGUID = if($FUGUIDS) {$FUGUIDS.replace('{', '').replace('}', '')}
    }
    
    $StickyUpdates = Get-Item -Path registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\StickyUpdates" -ErrorAction SilentlyContinue
    $StickyValueNames = if ($StickyUpdates) { $StickyUpdates.GetValueNames() }
    foreach ($name in $StickyValueNames) {
        if ($name.split('.')[0] -eq $FUGUID) {
            $FUDate = Get-ItemPropertyValue -Path registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\StickyUpdates" -Name $Name -ErrorAction SilentlyContinue
            [datetime]$FUDateTime = if($FUDate -is [string]) {
                $FUDate
            }
            else {
                [datetimeoffset]::FromUnixTimeSeconds($FUDate/1000)
            }
        }
        else {
            $QUDate = Get-ItemPropertyValue -Path registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\StickyUpdates" -Name $Name -ErrorAction SilentlyContinue
            [datetime]$QUDateTime = if($QUDate -is [string]) {
                $QUDate
            }
            else {
                [datetimeoffset]::FromUnixTimeSeconds($QUDate/1000).DateTime
            }
        }
    }

    $UpdateKeys = Get-ItemProperty Registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\current\device\Update" -ErrorAction SilentlyContinue
    $ConfigureDeadlineGracePeriod = $UpdateKeys.ConfigureDeadlineGracePeriod
    $ConfigureDeadlineGracePeriod_ProviderSet = $UpdateKeys.ConfigureDeadlineGracePeriod_ProviderSet
    $ConfigureDeadlineGracePeriod_WinningProvider = $UpdateKeys.ConfigureDeadlineGracePeriod_WinningProvider

    $ConfigureDeadlineForFeatureUpdates = $UpdateKeys.ConfigureDeadlineForFeatureUpdates
    $ConfigureDeadlineForFeatureUpdates_ProviderSet = $UpdateKeys.ConfigureDeadlineForFeatureUpdates_ProviderSet
    $ConfigureDeadlineForFeatureUpdates_WinningProvider = $UpdateKeys.ConfigureDeadlineForFeatureUpdates_WinningProvider

    if ( $ConfigureDeadlineForFeatureUpdates -and $ConfigureDeadlineForFeatureUpdates_ProviderSet -and $ConfigureDeadlineForFeatureUpdates_WinningProvider -and $FUDateTime) {
        Write-Host "FUSchedReboot: $($FUDateTime.AddDays($ConfigureDeadlineForFeatureUpdates).ToLocalTime().ToString())"
    } 
    elseif ($ConfigureDeadlineGracePeriod -and $ConfigureDeadlineGracePeriod_ProviderSet -and $ConfigureDeadlineGracePeriod_WinningProvider -and $QUDateTime -and $QURebootRequired) {
        Write-Host "QUSchedReboot: $($QUDateTime.AddDays($ConfigureDeadlineGracePeriod).ToLocalTime().ToString())"
    }
    elseif ($FUDateTime) {
        Write-Host "FUNoReboot: $($FUDateTime.ToString())"
    }
    elseif ($QUDateTime -and $QURebootRequired) {
        Write-Host "QUNoReboot: $($QUDateTime.ToString())"
    }
}
catch {
    $_
}