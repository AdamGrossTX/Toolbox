$SourceRoot = "C:\Users\rbell\Hinsdale Public Library\IT - General\Intune\Apps"
$OutputRoot = "C:\Users\rbell\Hinsdale Public Library\IT - General\Intune\Apps\IntuneWinApps"

#SonicWall
#Install CmdLine: msiexec.exe /i NetExtender-x64-10.2.322.msi /norestart /q /l*v c:\Windows\Temp\NetExtender-x64-10.2.322_Install.log ALLUSERS=2 DOMAIN=HPL SERVER=vpn.hinsdalelibrary.info:4433
#Uninstall CmdLine: msiexec /x "{EF06A6A8-6B81-4A09-8223-789953972FFF}" /q /norestart /l*v c:\Windows\Temp\NetExtender-x64-10.2.322_Uninstall.log
$IntuneAppSplat = @{
    SourceRoot = $SourceRoot
    SourceFolderName = "SonicWall NetExtender"
    SetupFileName = "NetExtender-x64-10.2.322.MSI"
    OutputRoot = $OutputRoot
}

#.\New-IntuneApp.ps1 @IntuneAppSplat


#AutoLogon
#Install CmdLine: %systemroot%\sysnative\WindowsPowershell\v1.0\powershell.exe -executionpolicy bypass -noprofile -noninteractive -command .\Configure-Autologon.ps1 -UserName thdesk@hinsdalelibrary.info -Password Hinsdale123 -Remediate $True
#Uninstall CmdLine: %systemroot%\sysnative\WindowsPowershell\v1.0\powershell.exe -executionpolicy bypass -noprofile -noninteractive -command .\Configure-Autologon.ps1 -Uninstall
$IntuneAppSplat = @{
    SourceRoot = $SourceRoot
    SourceFolderName = "AutoLogon"
    SetupFileName = "Configure-Autologon.ps1"
    OutputRoot = $OutputRoot
}

#.\New-IntuneApp.ps1 @IntuneAppSplat

#Firefox
#Install CmdLine: msiexec.exe /i NetExtender-x64-10.2.322.msi /norestart /q /l*v c:\Windows\Temp\NetExtender-x64-10.2.322_Install.log ALLUSERS=2 DOMAIN=HPL SERVER=vpn.hinsdalelibrary.info:4433
#Uninstall CmdLine: msiexec /x "{EF06A6A8-6B81-4A09-8223-789953972FFF}" /q /norestart /l*v c:\Windows\Temp\NetExtender-x64-10.2.322_Uninstall.log
$IntuneAppSplat = @{
    SourceRoot = $SourceRoot
    SourceFolderName = "Firefox"
    SetupFileName = "Firefox Setup 98.0.1.msi"
    OutputRoot = $OutputRoot
}

#.\New-IntuneApp.ps1 @IntuneAppSplat

#Chrome
#Install CmdLine: msiexec.exe /i NetExtender-x64-10.2.322.msi /norestart /q /l*v c:\Windows\Temp\NetExtender-x64-10.2.322_Install.log ALLUSERS=2 DOMAIN=HPL SERVER=vpn.hinsdalelibrary.info:4433
#Uninstall CmdLine: msiexec /x "{EF06A6A8-6B81-4A09-8223-789953972FFF}" /q /norestart /l*v c:\Windows\Temp\NetExtender-x64-10.2.322_Uninstall.log
$IntuneAppSplat = @{
    SourceRoot = $SourceRoot
    SourceFolderName = "Chrome"
    SetupFileName = "googlechromestandaloneenterprise64.msi"
    OutputRoot = $OutputRoot
}

#.\New-IntuneApp.ps1 @IntuneAppSplat

#Reader
#Install CmdLine: msiexec.exe /i NetExtender-x64-10.2.322.msi /norestart /q /l*v c:\Windows\Temp\NetExtender-x64-10.2.322_Install.log ALLUSERS=2 DOMAIN=HPL SERVER=vpn.hinsdalelibrary.info:4433
#Uninstall CmdLine: msiexec /x "{EF06A6A8-6B81-4A09-8223-789953972FFF}" /q /norestart /l*v c:\Windows\Temp\NetExtender-x64-10.2.322_Uninstall.log
$IntuneAppSplat = @{
    SourceRoot = $SourceRoot
    SourceFolderName = "Reader"
    SetupFileName = "AcroRdrDC2200120085_en_US.exe"
    OutputRoot = $OutputRoot
}

.\New-IntuneApp.ps1 @IntuneAppSplat