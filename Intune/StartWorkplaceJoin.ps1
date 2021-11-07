#https://www.maximerastello.com/manually-re-enroll-a-co-managed-or-hybrid-azure-ad-join-windows-10-pc-to-microsoft-intune-without-loosing-current-configuration/

function Get-DSREGCMDStatus {
    [cmdletbinding()]
    param()
    try {
        $DSREGCMDStatus = & DSREGCMD /Status
        $DSREGCMDEntries =
        for($i = 0; $i -le $DSREGCMDStatus.Count ; $i++) {
            if($DSREGCMDStatus[$i] -like "*|*") {
                $GroupName = $DSREGCMDStatus[$i].Replace("|","").Trim()
            }
            elseif($DSREGCMDStatus[$i] -like "*:*") {
                $EntryParts = $DSREGCMDStatus[$i].split(":")
                [PSCustomObject] @{
                    GroupName = $GroupName
                    PropertyName = $EntryParts[0].Trim()
                    PropertyValue = $EntryParts[1].Trim()
                }
            }
        }

        return $DSREGCMDEntries
    }
    catch {
        return $_
    }
}
try {
        Write-Output "Enabling AutoJoin Task"
        $AADKey = New-Item -Path registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin" -Force -ErrorAction SilentlyContinue
        $AADKey | New-ItemProperty -Name "autoWorkplaceJoin" -Value 1 -PropertyType DWORD -Force -ErrorAction SilentlyContinue | Out-Null

        $AutoJoinTask = Get-ScheduledTask -TaskPath "\Microsoft\Windows\Workplace Join\" -TaskName "Automatic-Device-Join"
        $AutoJoinTask | Enable-ScheduledTask
        $AutoJoinTask | Start-ScheduledTask
        Start-Sleep -Seconds 10

        $DeviceSyncTask = Get-ScheduledTask -TaskPath "\Microsoft\Windows\Workplace Join\" -TaskName "Device-Sync"
        $DeviceSyncTask | Enable-ScheduledTask
        $DeviceSyncTask | Start-ScheduledTask
        Start-Sleep -Seconds 10

        $Status = Get-DSREGCMDStatus
        $Status | Select-Object *
}
catch {
    throw $_
}