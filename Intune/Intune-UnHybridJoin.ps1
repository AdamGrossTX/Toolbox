<#
.SYNOPSIS
Simple script to format DSREGCMD /Status output

.DESCRIPTION
Simple script to format DSREGCMD /Status output

.PARAMETER Remediate
Set to 1 to delete Intune enrollment and disjoin from AAD
Exclude or set to 0 to return information only. No changes are made.

.PARAMETER ReJoin
Set to 1 to set registry key to trigger Azure AD Join

.EXAMPLE
UnJoin and UnEnroll but don't rejoin. Great for use with Master Image prep.
PS C:\> .\Intune-UnHybridJoin.ps1 -Remediate 1

.EXAMPLE
UnJoin and UnEnroll and ReJoin. Great for devices that are already deployed that need to be fixed.
PS C:\> .\Intune-UnHybridJoin.ps1 -Remediate 1 -Rejoin 1


.NOTES
    Version:          1.0
    Author:           Adam Gross - @AdamGrossTX
    GitHub:           https://www.github.com/AdamGrossTX
    WebSite:          https://www.asquaredozen.com
    Creation Date:    11/13/2021

    Thanks to https://www.maximerastello.com/manually-re-enroll-a-co-managed-or-hybrid-azure-ad-join-windows-10-pc-to-microsoft-intune-without-loosing-current-configuration/


    This hasn't been tested against Co-Managed Azure AD Only devices. It may need some work there still.

    Yes, I know the script name isn't accurate, but it is what it is now.

    If you continue to have issues with re-joining, you may need to delete the AAD, Intune and Autopilot device objects from your tentant then wait for Azure AD Connect to re-sync.

#>

[cmdletbinding()]
param (
    [Parameter()]
    [ValidateSet(0, 1)]
    [int]$Remediate,

    [Parameter()]
    [ValidateSet(0, 1)]
    [int]$ReJoin
)
function Get-DSREGCMDStatus {
    [cmdletbinding()]
    param(
        [parameter(HelpMessage = "Use to add /DEBUG to DSREGCMD")]
        [switch]$bDebug #Can't use Debug since it's a reserved word
    )
    try {
        $cmdArgs = if ($bDebug) { "/STATUS", "/DEBUG" } else { "/STATUS" }
        $DSREGCMDStatus = & DSREGCMD $cmdArgs
    
        $DSREGCMDEntries = [PSCustomObject]@{}
    
        if ($DSREGCMDStatus) {
            for ($i = 0; $i -le $DSREGCMDStatus.Count ; $i++) {
                if ($DSREGCMDStatus[$i] -like "| *") {
                    $GroupName = $DSREGCMDStatus[$i].Replace("|", "").Trim().Replace(" ", "")
                    $Member = @{
                        MemberType = "NoteProperty"
                        Name       = $GroupName
                        Value      = $null
                    }
                    $DSREGCMDEntries | Add-Member @Member
                    $i++ #Increment to skip next line with +----
                    $GroupEntries = [PSCustomObject]@{}
    
                    do {
                        $i++
                        if ($DSREGCMDStatus[$i] -like "*::*") {
                            $DiagnosticEntries = $DSREGCMDStatus[$i] -split "(^DsrCmd.+(?=DsrCmd)|DsrCmd.+(?=\n))" | Where-Object { $_ -ne '' }
                            foreach ($Entry in $DiagnosticEntries) {
                                $EntryParts = $Entry -split "(^.+?::.+?: )" | Where-Object { $_ -ne '' }
                                $EntryParts[0] = $EntryParts[0].Replace("::", "").Replace(": ", "")
                                if ($EntryParts) {
                                    $Member = @{
                                        MemberType = "NoteProperty"
                                        Name       = $EntryParts[0].Trim().Replace(" ", "")
                                        Value      = $EntryParts[1].Trim()
                                    }
                                    $GroupEntries | Add-Member @Member -Force
                                    $Member = $null
                                }
                            }
                        }
                        elseif ($DSREGCMDStatus[$i] -like "* : *") {
                            $EntryParts = $DSREGCMDStatus[$i] -split ':'
                            if ($EntryParts) {
                                $Member = @{
                                    MemberType = "NoteProperty"
                                    Name       = $EntryParts[0].Trim().Replace(" ", "")
                                    Value      = $EntryParts[1].Trim()
                                }
                                $GroupEntries | Add-Member @Member -Force
                                $Member = $null
                            }
                        }
                        
                    } until($DSREGCMDStatus[$i] -like "+-*" -or $i -eq $DSREGCMDStatus.Count)
        
                    $DSREGCMDEntries.$GroupName = $GroupEntries
                }
            }
            return $DSREGCMDEntries
        }
        else {
            return "No Status Found"
        }
    }
    catch {
        throw $_
    }
}

try {

    [string[]]$ProviderGUIDs = @()

    #region Get MS DM Provider GUID
    #Gets enrollment registry keys where the value is MS DM Server.  This will find the MDM/Intune enrollment GUID that we will use for all of the other steps.
    $ProviderRegistryPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments"
    $ProviderPropertyName = "ProviderID"
    $ProviderPropertyValue = "MS DM Server"
    $ProviderGUID = (Get-ChildItem -Path Registry::$ProviderRegistryPath -Recurse -ErrorAction SilentlyContinue | ForEach-Object { if ((Get-ItemProperty -Name $ProviderPropertyName -Path $_.PSPath -ErrorAction SilentlyContinue | Get-ItemPropertyValue -Name $ProviderPropertyName -ErrorAction SilentlyContinue) -match $ProviderPropertyValue) { $_ } }).PSChildName
    if ($ProviderGUID) {
        $ProviderGUIDs += $ProviderGUID
        Write-Output "Provider GUID Found $($ProviderGUID)"
    }
    else {
        Write-Output "No Provider GUID Found"
    }
    #endregion

    #region Check for System and Admin
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (($Env:USERNAME).Replace("`$", "") -eq $Env:COMPUTERNAME) {
        Write-Output "Running As System"
    }
    else {
        Write-Output "Not Running as System"
    }

    if ($isAdmin) {
        Write-Output "Has Admin Rights"
    }
    else {
        Write-Output "Does not have Admin Rights"
    }
    #endregion

    #region DSREGCMD
    #Runs DSREGCMD to get information about the Azure AD Joined state of the device. If it is joined, it will also return the device ID.
    
    $DSRegCmdStatus = Get-DSREGCMDStatus
    $AzureAdJoined = $DSRegCmdStatus.DeviceState.AzureAdJoined
    $DomainJoined = $DSRegCmdStatus.DeviceState.DomainJoined
    $DeviceId = $DSRegCmdStatus.DeviceDetails.DeviceId
    if ($DSRegCmdStatus.DiagnosticData.ClientErrorCode) {
        $DSRegCmdStatus.DiagnosticData | Foreach-Object { Write-Output $_ }
    }
    
    Write-Output "Azure Device ID:  $($DeviceId)"
    #If the device is hybird joined and is remediate = 1 then run Disjoin from AAD.
    if ($AzureAdJoined -eq "Yes" -and $DomainJoined -eq "Yes") {
        Write-Output "Device is Hybrid Joined"
    }

    #region Tasks
    #Finds all scheduled tasks using the Enrollment GUID and deletes them
    $TaskPath = "\Microsoft\Windows\EnterpriseMgmt\"
    $TaskRegistryPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\EnterpriseMgmt"
    $EnterpriseMgmtTasks = (Get-ChildItem -Path Registry::$TaskRegistryPath -ErrorAction SilentlyContinue).PSChildName | Where-Object { $_ -ne "VirtulizationBasedIsolation" }

    foreach ($TaskGUID in $EnterpriseMgmtTasks) {
        $ProviderGUIDs += $TaskGUID
        $Tasks = Get-ScheduledTask -TaskPath "$(Join-Path -Path $($TaskPath) -ChildPath $($TaskGUID))\*" -ErrorAction SilentlyContinue
        if ($Remediate -eq 1 -and $Tasks) {
            Write-Output "Deleting Scheduled Tasks"

            $scheduleObject = New-Object -ComObject schedule.service
            $scheduleObject.connect()
            $rootFolder = $scheduleObject.GetFolder("\")

            foreach ($Task in $Tasks) {
                $ParentFolder = $Task.TaskPath.TrimEnd("\")
                $Task | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
            }
            try {
                $rootFolder.DeleteFolder($ParentFolder, $null)
            }
            catch {
                continue
            }
        }
        elseif ($Tasks) {
            Write-Output "Found Tasks"
        }
    }
    #endregion

    #region Remove Intune Device Registration Info
    if ($ProviderGUIDs) {
        $ProviderGUIDs = $ProviderGUIDs | Get-Unique
        foreach ($GUID in $ProviderGUIDs) {
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
            if ($EntDMID) {
                $ActiveProviderGUID = $GUID
                $ActiveIntuneDeviceID = $EntDMID
                #Write-Output "ActiveProviderGUID:         $($ActiveProviderGUID)"
                #Write-Output "ActiveIntuneDeviceID:         $($ActiveIntuneDeviceID)"
            }            #endregion
            Write-Output "TaskGUID:         $($GUID)"
            Write-Output "EntDMID:          $($EntDMID)"
            Write-Output "EntDeviceName:    $($EntDeviceName)"

            #region delete Intune Device Registrion registry keys
            foreach ($key in $KeyList) {
                $KeyInstance = Get-Item -Path Registry::$($Key) -ErrorAction SilentlyContinue
                if ($KeyInstance) {
                    if ($Remediate -eq 1) {
                        Write-Output "Removing:         $($KeyInstance.Name)"
                        $KeyInstance | Remove-Item -Force -Recurse -ErrorAction Continue
                    }
                    else {
                        Write-Output "Found:            $($KeyInstance.Name)"
                    }
                }
            }
        }
    }

    if ($Remediate -eq 1) {
        Get-Item -Path registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning\OMADM" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }

    #endregion

    #region Cleanup Intune and Azure Certs
    $IntuneCertIssuer = "CN=Microsoft Intune MDM Device CA"
    $AzureIssuer = "*CN=MS-Organization-*Access*"
    $IntuneCert = Get-ChildItem -Path "cert:\LocalMachine\My" | Where-Object { $_.Issuer -eq $IntuneCertIssuer }
    if ($IntuneCert) {
        $IntuneDeviceID = ($IntuneCert.SubjectName.Name.Split(',') | Where-Object { $_ -like 'CN=*' }).trim().Replace('CN=', '')
        Write-Output "IntuneDeviceID:   $($IntuneDeviceID)"
        if ($Remediate -eq 1) {
            Write-Output "Removing Intune Cert"
            $IntuneCert | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        else {
            Write-Output "Intune Cert:      $($IntuneCert.Thumbprint)"
        }
    }

    $AzureCert = Get-ChildItem -Path "cert:\LocalMachine\My" | Where-Object { $_.Issuer -like $AzureIssuer }
    if ($AzureCert) {
        $AzureDeviceID = ($AzureCert.SubjectName.Name.Split(',') | Where-Object { $_ -like 'CN=*' } | Select-Object -Unique).trim().Replace('CN=', '')
        Write-Output "AzureDeviceID:    $($AzureDeviceID)"
        if ($Remediate -eq 1) {
            Write-Output "Removing Azure Cert"
            $AzureCert | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        else {
            Write-Output "Azure Cert:       $($AzureCert.Thumbprint)"
        }
    }
    #endregion

    if ($Remediate -eq 1) {
        Get-Item -Path registry::"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\Diagnostics" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue #Reset the AAD Join Error Status
        $LeaveResult = & DSREGCMD /LEAVE /DEBUG
        Write-Output $LeaveResult
        $DSRegCmdStatus = Get-DSREGCMDStatus
        $AzureAdJoined = $DSRegCmdStatus.DeviceState.AzureAdJoined
        $DomainJoined = $DSRegCmdStatus.DeviceState.DomainJoined
        $DeviceId = $DSRegCmdStatus.TenantDetails.WorkplaceDeviceId
        if ($DSRegCmdStatus.DiagnosticData.ClientErrorCode) {
            $DSRegCmdStatus.DiagnosticData | Foreach-Object { Write-Output $_ }
        }
    }

    #endregion

    
    #region Rejoin
    #If Rejoin = 1 then add registry key to enable Azure AD Join then trigger the Workplace Join scheduled tasks for good measure.
    if ($ReJoin -eq 1) {
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
    #endregion
    
    $Return = $True
    if (-not $IntuneCert.Thumbprint) {
        Write-Output "Missing Intune Cert"
        $Return = $False
    }

    if (-not $AzureCert.Thumbprint) {
        Write-Output "Missing Azure Cert"
        $Return = $False
    }

    if ((-not $ActiveIntuneDeviceID) -or (-not $IntuneDeviceID)) {
        Write-Output "Missing Intune Device ID"
        $Return = $False
    }

    if (-not $AzureDeviceID) {
        Write-Output "Missing Azure AD Device ID"
        $Return = $False
    }
    
    return $Return
}
catch {
    throw $_
}