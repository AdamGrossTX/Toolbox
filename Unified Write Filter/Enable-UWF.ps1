#Unified Write Filter Management
#https://learn.microsoft.com/en-us/windows-hardware/customize/enterprise/uwfexclusions
#https://learn.microsoft.com/en-us/windows-hardware/customize/enterprise/unified-write-filter
#https://github.com/helmlingp/euc-samples/tree/2827f64711e39d5d5258575a0e90269eb75df110/UEM-Samples/Profiles/Windows/Unified%20Write%20Filter
#https://learn.microsoft.com/en-us/windows-hardware/customize/enterprise/uwf-apply-oem-updates
#https://learn.microsoft.com/en-us/windows-hardware/customize/enterprise/service-uwf-protected-devices


#https://learn.microsoft.com/en-us/windows-hardware/customize/enterprise/uwf-apply-windows-updates

#http://woshub.com/using-unified-write-filter-uwf-windows-10/

#https://www.powershellgallery.com/packages/UWFModule/0.0.3


#Unified Write Filter Management
#https://learn.microsoft.com/en-us/windows-hardware/customize/enterprise/uwfexclusions
#https://learn.microsoft.com/en-us/windows-hardware/customize/enterprise/unified-write-filter
#https://github.com/helmlingp/euc-samples/tree/2827f64711e39d5d5258575a0e90269eb75df110/UEM-Samples/Profiles/Windows/Unified%20Write%20Filter

#https://learn.microsoft.com/en-us/windows-hardware/customize/enterprise/uwf-apply-windows-updates

#http://woshub.com/using-unified-write-filter-uwf-windows-10/



#UWF does not support the use of fast startup when shutting down your device. If fast startup is turned on, shutting down the device does not clear the overlay. You can disable fast startup in Control Panel by navigating to Control Panel > All Control Panel Items > Power Options > System Settings and clearing the checkbox next to Turn on fast startup (recommended).

param(
    [switch]$remediate = $true
)

Start-Transcript -Path C:\ProgramData\Microsoft\IntuneMangementExtension\Logs\UWFLog.log -Force -ErrorAction SilentlyContinue

$RegKeyList = @(
    "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\BITS\StateIndex",
    "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Wireless\GPTWirelessPolicy",
    "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WiredL2\GP_Policy",
    "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\wlansvc",
    "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\dot3svc",
    "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Wlansvc",
    "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\WwanSvc",
    "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\dot3svc",
    "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WdBoot",
    "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WdFilter",
    "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WdNisDrv",
    "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WinDefend",
    "HKEY_LOCAL_MACHINE\SOFTWARE\SOFTWARE\Policies\Microsoft\AzureADAccount\PreferredTenantDomainName",
    "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones",
    "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation",
    "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender"
)

$PathList = @(
    "%ALLUSERSPROFILE%\Microsoft\Network\Downloader",
    "\ProgramData\Microsoft\wlansvc\Profiles",
    "\ProgramData\Logs",
    "\ProgramData\Config",
    "\ProgramData\Microsoft\dot3svc\Profiles",
    "\Program Files\Windows Defender",
    "\ProgramData\Microsoft\Windows Defender",
    "\Windows\WindowsUpdate.log",
    "\Windows\Temp\MpCmdRun.log",
    "\ProgramData\Microsoft\IntuneMangementExtension",
    "\Windows\IMECache",
    "\Windows\IME"
)


try {
    $Key = Get-Item -Path registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\AzureADAccount" -ErrorAction SilentlyContinue
    if ($Key) {
        if ($remediate.IsPresent) {
            $Key | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
        else {
            Write-Warning "PreferredTenantDomainName registry key found."
            Exit 1
        }
    }
    else {
        Write-Host "AzureADAccount Reg Key not found."
    }

    $UWFFeatureState = (Get-WindowsOptionalFeature -FeatureName "Client-UnifiedWriteFilter" -Online -ErrorAction SilentlyContinue).State
    If ($UWFFeatureState -eq "Disabled") {
        if ($Remediate.IsPresent) {
            $Return = Enable-WindowsOptionalFeature -Online -FeatureName "Client-UnifiedWriteFilter" -NoRestart -All -ErrorAction Continue
            Write-Host "Enabled UWF Feature"
        }
        else {
            Write-Warning "The Unified Write Filter Feature is currently disabled. Use Enable-UWFFeature to enable it before useing this module."
            exit 1
        }
    }

    $UWFNameSpace = "root\standardcimv2\embedded"
    $UWF = Get-CIMInstance -Namespace $UWFNameSpace -ClassName UWF_Filter -ErrorAction SilentlyContinue
    $UWFOverlay = Get-CIMInstance -Namespace $UWFNameSpace -ClassName UWF_Overlay -ErrorAction SilentlyContinue
    $UWFOverlayConfig = Get-CIMInstance -Namespace $UWFNameSpace -ClassName UWF_OverlayConfig | Where-Object { $_.CurrentSession -eq $false } -ErrorAction SilentlyContinue
    $UWFServicing = Get-CIMInstance -Namespace $UWFNameSpace -ClassName UWF_Servicing -ErrorAction SilentlyContinue
    $UWFVolume = Get-CIMInstance -Namespace $UWFNameSpace -ClassName UWF_Volume | Where-Object { $_.CurrentSession -eq $false -and $_.DriveLetter -eq "c:" }
    $UWFRegistryFilter = Get-CIMInstance -Namespace $UWFNameSpace -ClassName UWF_RegistryFilter | Where-Object { $_.CurrentSession -eq $false }


    if ($UWFOverlayConfig.Type -ne 1) {
        if ($remediate.IsPresent) {
            $Return = $UWFOverlayConfig | Invoke-CimMethod -MethodName SetType -Arguments @{type = 1 }
            Write-Host "Set UWF Type to Disk"
        }
        else {
            Write-Warning "UWF Type set to type $($UWFOverlayConfig.Type)."
        }
    }

    if ($UWFOverlayConfig.MaximumSize -ne 16500) {
        if ($remediate.IsPresent) {
            $Return = $UWFOverlayConfig | Invoke-CimMethod -MethodName SetMaximumSize -Arguments @{size = 16500 }
            Write-Host "Set UWF Overlay Max Size"
        }
        else {
            Write-Warning "UWF Overlay Max Size is invalid."
        }
    }

    if ($UWFOverlay.WarningOverlayThreshold -ne 14000) {
        if ($remediate.IsPresent) {
            $Return = $UWFOverlay | Invoke-CimMethod -MethodName SetWarningThreshold -Arguments @{size = 14000 }
            Write-Host "Set UWF WarningOverlayThreshold Size"
        }
        else {
            Write-Warning "UWF WarningOverlayThreshold Size is invalid."
        }
    }

    if ($UWFOverlay.CriticalOverlayThreshold -ne 15000) {
        if ($remediate.IsPresent) {
            $Return = $UWFOverlay | Invoke-CimMethod -MethodName SetCriticalThreshold -Arguments @{size = 15000 }
            Write-Host "Set UWF CriticalOverlayThreshold Size"
        }
        else {
            Write-Warning "UWF CriticalOverlayThreshold Size is invalid."
        }
    }

    if ($UWF.CurrentEnabled -eq $false) {
        if ($remediate.IsPresent) {
            $Return = $UWF | Invoke-CimMethod -MethodName Enable
            Write-Host "Enabled UWF"
        }
        else {
            Write-Warning "UWF feature installed but not enabled."
            Exit 1
        }
    }

    if (-not($UWFVolume) -or ($UWFVolume.Protected -eq $false)) {
        if ($remediate.IsPresent) {
            uwfmgr.exe volume protect c:
            $UWFVolume = Get-CIMInstance -Namespace $UWFNameSpace -ClassName UWF_Volume | Where-Object { $_.CurrentSession -eq $false -and $_.DriveLetter -eq "c:" }
            $Return = $UWFVolume | Invoke-CimMethod -MethodName Protect
            Write-Host "UWF Volume Protected"
        }
        else {
            Write-Warning "UWF Volume protection not enabled."
            Exit 1
        }
    }


    foreach ($key in $RegKeyList) {
        if (($UWFRegistryFilter | Invoke-CimMethod -MethodName FindExclusion -Arguments @{RegistryKey = $Key }).bFound -eq $false) {
            if ($remediate) {
                $return = $UWFRegistryFilter | Invoke-CimMethod -MethodName AddExclusion -Arguments @{RegistryKey = $Key }
                Write-Host "Added Exclusion for $Key"
            }
            else {
                Write-Warning "Registry exclusion missing for $($Key)"
                exit 0
            }
        }
    }

    foreach ($path in $PathList) {
        if (($UWFVolume | Invoke-CimMethod -MethodName FindExclusion -Arguments @{FileName = $path }).bFound -eq $false) {
            if ($remediate) {
                $return = $UWFVolume | Invoke-CimMethod -MethodName AddExclusion -Arguments @{FileName = $path }
                Write-Host "Added Exclusion for $path"
            }
            else {
                Write-Warning "File exclusion missing for $($path)"
                exit 0
            }
        }
    }
    Stop-Transcript
}
catch {
    throw $_
}