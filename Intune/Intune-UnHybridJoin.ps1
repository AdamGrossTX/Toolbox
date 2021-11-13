
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

#>

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
    param(
        [parameter(HelpMessage="Use to add /DEBUG to DSREGCMD")]
        [switch]$bDebug #Can't use Debug since it's a reserved word
    )
    
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

    #region DSREGCMD
    #Runs DSREGCMD to get information about the Azure AD Joined state of the device. If it is joined, it will also return the device ID.
    
    $DSRegCmdStatus = Get-DSREGCMDStatus
    if(($DSRegCmdStatus | Where-Object {$_.PropertyName -eq "AzureAdJoined"} | Select-Object -ExpandProperty PropertyValue) -eq "Yes") {
        $AzureAdJoined = $DSRegCmdStatus | Where-Object {$_.PropertyName -eq "AzureAdJoined"} | Select-Object -ExpandProperty PropertyValue
        $DomainJoined = $DSRegCmdStatus | Where-Object {$_.PropertyName -eq "DomainJoined"} | Select-Object -ExpandProperty PropertyValue
        $DeviceId = $DSRegCmdStatus | Where-Object {$_.PropertyName -eq "DeviceId"} | Select-Object -ExpandProperty PropertyValue
    }

    Write-Output "Azure Device ID:  $($DeviceId)"

    #If the device is hybird joined and is remediate = 1 then run Disjoin from AAD.
    if($AzureAdJoined -eq "Yes" -and $DomainJoined -eq "Yes") {
        Write-Output "Device is Hybrid Joined"
        if($Remediate -eq 1) {
            $LeaveResult = & DSREGCMD /Leave
            Write-Output $LeaveResult
        }
    }
    #endregion

    #region Tasks
    #Finds all scheduled tasks using the Enrollment GUID and deletes them
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

    #Region Outputs
    Write-Output "AzureDeviceID:    $($AzureDeviceID)"
    Write-Output "IntuneDeviceID:   $($IntuneDeviceID)"

    $TaskGUID = $null
    $AzureDeviceID = $null
    $IntuneDeviceID = $null
    $EntDMID = $null
    $EntDeviceName = $null

    #region Rejoin
    #If Rejoin = 1 then add registry key to enable Azure AD Join then trigger the Workplace Join scheduled tasks for good measure.
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
    #endregion
}
catch {
    throw $_
}