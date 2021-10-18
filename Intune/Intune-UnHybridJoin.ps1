#https://www.maximerastello.com/manually-re-enroll-a-co-managed-or-hybrid-azure-ad-join-windows-10-pc-to-microsoft-intune-without-loosing-current-configuration/

[cmdletbinding()]
param (
    [Parameter()]
    [ValidateSet(0,1)]
    [int]$Remediate,

    [Parameter()]
    [ValidateSet(0,1)]
    [int]$ReJoin
)

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

    [string[]]$ProviderGUIDs = @()

    #region Get MS DM Provider GUID
    $ProviderRegistryPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments"
    $ProviderPropertyName = "ProviderID"
    $ProviderPropertyValue = "MS DM Server"
    $ProviderGUID = (Get-ChildItem -Path Registry::$ProviderRegistryPath -Recurse -ErrorAction SilentlyContinue | ForEach-Object { if((Get-ItemProperty -Name $ProviderPropertyName -Path $_.PSPath -ErrorAction SilentlyContinue | Get-ItemPropertyValue -Name $ProviderPropertyName -ErrorAction SilentlyContinue) -match $ProviderPropertyValue) { $_ } }).PSChildName
    if($ProviderGUID) {
        $ProviderGUIDs += $ProviderGUID
        Write-Output "Provider GUID Found $($ProviderGUID)"
    }
    else {
        Write-Output "No Provider GUID Found"
    }
    #endregion

    #region Check for System and Admin
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if(($Env:USERNAME).Replace("`$","") -eq $Env:COMPUTERNAME) {
        Write-Output "Running As System"
    }
    else {
        Write-Output "Not Running as System"
    }

    if($isAdmin) {
        Write-Output "Has Admin Rights"
    }
    else {
        Write-Output "Does not have Admin Rights"
    }
    #endregion

    $DSRegCmdStatus = Get-DSREGCMDStatus
    if(($DSRegCmdStatus | Where-Object {$_.PropertyName -eq "AzureAdJoined"} | Select-Object -ExpandProperty PropertyValue) -eq "Yes") {
        $AzureAdJoined = $DSRegCmdStatus | Where-Object {$_.PropertyName -eq "AzureAdJoined"} | Select-Object -ExpandProperty PropertyValue
        $DomainJoined = $DSRegCmdStatus | Where-Object {$_.PropertyName -eq "DomainJoined"} | Select-Object -ExpandProperty PropertyValue
        $DeviceId = $DSRegCmdStatus | Where-Object {$_.PropertyName -eq "DeviceId"} | Select-Object -ExpandProperty PropertyValue
    }

    Write-Output "Azure Device ID:  $($DeviceId)"

    if($AzureAdJoined -eq "Yes" -and $DomainJoined -eq "Yes") {
        Write-Output "Device is Hybrid Joined"
        if($Remediate -eq 1) {
            $LeaveResult = & DSREGCMD /Leave
            Write-Output $LeaveResult
        }
    }

    #region Tasks
    $TaskPath = "\Microsoft\Windows\EnterpriseMgmt\"
    $TaskRegistryPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\EnterpriseMgmt"
    $EnderpriseMgmtTasks = (Get-ChildItem -Path Registry::$TaskRegistryPath -ErrorAction SilentlyContinue).PSChildName

    foreach($TaskGUID in $EnderpriseMgmtTasks) {
        $ProviderGUIDs += $TaskGUID
        $Tasks = Get-ScheduledTask -TaskPath "$(Join-Path -Path $($TaskPath) -ChildPath $($TaskGUID))\*" -ErrorAction SilentlyContinue
        if($Remediate -eq 1 -and $Tasks) {
            Write-Output "Deleting Scheduled Tasks"

            $scheduleObject = New-Object -ComObject schedule.service
            $scheduleObject.connect()
            $rootFolder = $scheduleObject.GetFolder("\")

            foreach($Task in $Tasks) {
                $ParentFolder = $Task.TaskPath.TrimEnd("\")
                $Task | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
            }
            try {
                $rootFolder.DeleteFolder($ParentFolder,$null)
            }
            catch {
                continue
            }
        }
        elseif($Tasks) {
            Write-Output "Found Tasks"
        }
    }
    #endregion

    #region Remove Intune Device Registration Info
    if($ProviderGUIDs) {
        $ProviderGUIDs = $ProviderGUIDs | Get-Unique
        foreach($GUID in $ProviderGUIDs) {
            [string[]]$KeyList = @(
                "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments\$($GUID)"
                "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments\Status\$($GUID)"
                "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked\$($GUID)"
                "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\AdmxInstalled\$($GUID)"
                "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\Providers\$($GUID)"
                "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\$($GUID)"
                "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning\OMADM\Logger\$($GUID)"
                "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning\OMADM\Sessions\$($GUID)"
            )

            $DMClientPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments\$($GUID)\DMClient\MS DM Server"
            $EntDMID = Get-ItemPropertyValue -Path Registry::$DMClientPath -Name "EntDMID" -ErrorAction SilentlyContinue
            $EntDeviceName = Get-ItemPropertyValue -Path Registry::$DMClientPath -Name "EntDeviceName" -ErrorAction SilentlyContinue
            #endregion
            Write-Output "TaskGUID:         $($GUID)"
            Write-Output "EntDMID:          $($EntDMID)"
            Write-Output "EntDeviceName:    $($EntDeviceName)"

            #region delete Intune Device Registrion registry keys
            foreach($key in $KeyList) {
                $KeyInstance = Get-Item -Path Registry::$($Key) -ErrorAction SilentlyContinue
                if($KeyInstance) {
                    if($Remediate -eq 1) {
                        Write-Output "Removing:         $($KeyInstance.Name)"
                        $KeyInstance | Remove-Item -Force -Recurse -ErrorAction Continue
                    }
                    else {
                        Write-Output "Found:            $($KeyInstance.Name)"
                    }
                }
            }
            if($Remediate -eq 1) {
                Get-Item -Path registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning\OMADM" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    #endregion

    #region Cleanup Intune and Azure Certs
    $IntuneCertIssuer = "CN=Microsoft Intune MDM Device CA"
    $AzureIssuer = "CN=MS-Organization-*Access*"
    $IntuneCert = Get-ChildItem -Path "cert:\LocalMachine\My" | Where-Object {$_.Issuer -eq $IntuneCertIssuer}
    if($IntuneCert) {
        $IntuneDeviceID = ($IntuneCert.SubjectName.Name.Split(',') | Where-Object {$_ -like 'CN=*'}).trim().Replace('CN=','')
        if($Remediate -eq 1) {
            Write-Output "Removing Intune Cert"
            $IntuneCert | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        else {
            Write-Output "Intune Cert:      $($IntuneCert.Thumbprint)"
        }
    }

    $AzureCert = Get-ChildItem -Path "cert:\LocalMachine\My" | Where-Object {$_.Issuer -like $AzureIssuer}
    if($AzureCert) {
        $AzureDeviceID = ($AzureCert.SubjectName.Name.Split(',') | Where-Object {$_ -like 'CN=*'}).trim().Replace('CN=','')
        if($Remediate -eq 1) {
            Write-Output "Removing Azure Cert"
            $AzureCert | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        else {
            Write-Output "Azure Cert:       $($AzureCert.Thumbprint)"
        }
    }
    #endregion

    Write-Output "AzureDeviceID:    $($AzureDeviceID)"
    Write-Output "IntuneDeviceID:   $($IntuneDeviceID)"

    $TaskGUID = $null
    $AzureDeviceID = $null
    $IntuneDeviceID = $null
    $EntDMID = $null
    $EntDeviceName = $null

    if($ReJoin -eq 1) {
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
}
catch {
    throw $_
}