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
    $UWFNameSpace = "root\standardcimv2\embedded"
    $UWF = Get-CIMInstance -Namespace $UWFNameSpace -ClassName UWF_Filter -ErrorAction SilentlyContinue
    $UWFOverlay = Get-CIMInstance -Namespace $UWFNameSpace -ClassName UWF_Overlay -ErrorAction SilentlyContinue
    $UWFOverlayConfig = Get-CIMInstance -Namespace $UWFNameSpace -ClassName UWF_OverlayConfig | Where-Object { $_.CurrentSession -eq $false } -ErrorAction SilentlyContinue
    $UWFServicing = Get-CIMInstance -Namespace $UWFNameSpace -ClassName UWF_Servicing -ErrorAction SilentlyContinue
    $UWFVolume = Get-CIMInstance -Namespace $UWFNameSpace -ClassName UWF_Volume | Where-Object { $_.CurrentSession -eq $false -and $_.DriveLetter -eq "c:" }
    $UWFRegistryFilter = Get-CIMInstance -Namespace $UWFNameSpace -ClassName UWF_RegistryFilter | Where-Object { $_.CurrentSession -eq $false }
    
    if (($UWFVolume) -or ($UWFVolume.Protected -eq $true)) {
        if ($remediate.IsPresent) {
            uwfmgr.exe volume unprotect c:
            $UWFVolume = Get-CIMInstance -Namespace $UWFNameSpace -ClassName UWF_Volume | Where-Object { $_.CurrentSession -eq $false -and $_.DriveLetter -eq "c:" }
            $Return = $UWFVolume | Invoke-CimMethod -MethodName UnProtect
            Write-Host "UWF Volume UnProtected"
        }
        else {
            Write-Warning "UWF Volume protection enabled."
            Exit 1
        }
    }

    if ($UWF.CurrentEnabled -eq $true) {
        if ($remediate.IsPresent) {
            $Return = $UWF | Invoke-CimMethod -MethodName Disable
            Write-Host "Disabled UWF"
        }
        else {
            Write-Warning "UWF feature is enabled"
            Exit 1
        }
    }
}
catch {
    throw $_
}

