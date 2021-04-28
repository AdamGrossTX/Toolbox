
#New-BootImage
$BootImageSplat = @{
    SiteCode = "PS1"
    SiteServer = "CM01.asd.net"
    BootImageRoot = "\\cm01\Media\BootImages"
    Arch = "x64"
    BootImageFolderName = "WinPE10x64-ADK1903-$(Get-Date -Format yyyyMMdd)"
    BootImageName = "Prod - Boot Image $(Get-Date -Format yyyyMMdd)"
    BootImageDescription = "ADK 1903 $(Get-Date -Format yyyyMMdd)"
    DPGroupName = "All Distribution Points"
    ConsoleFolder = "Windows 10"
    DriverCategoryName = "WinPE"
    PrestartCommandLine = "Custom.cmd"
    PrestartIncludeFilesDirectory = ".\Pre-Start"
    ConsoleFolderPath = "\Production Boot Images"
}

.\New-BootImage @BootImageSplat


#Update-BootImage
$UpdateBootImageSplat = @{
    ConfigMgrBootWim = "E:\Program Files\Microsoft Configuration Manager\OSD\boot\x64\boot.wim"
    BootImagesPath = "E:\Media\BootImages\"
    NewFolderName = "WinPE1809_20190414"
    MountDir = "F:\Mount"
    CustomFiles = "$($PSScriptRoot)\Custom"
    CustomFolders = (Get-ChildItem -Path $CustomFiles)
    BootWIMUNC = "\\CM01\Media\BootImages\WinPE1809_20190414\boot.wim"
    SiteCode = "PS1"
    ServerName = "CM01.asd.net"
}

.\UpdateBootImage.ps1 @UpdateBootImageSplat

#Import-WindowsImage
$ImportWindowsImageSplat = @{
    ServerName = "cm01.asd.net"
    SiteCode = "PS1"
    SourceMediaRootPath = "C:\ImageServicing\CompletedMedia"
    DestinationRootPath = "\\sources\OSInstallFiles\Windows 10"
    OSVersion = "1909"
    OSArch = "x64" 
    Month = "2019-12"
    ImageType = "Both"
    ConsoleFolderPath = "\Windows 10"
    DPGroupName = "All Distribution Points"
}

.\Import-WindowsImage.ps1 @ImportWindowsImageSplat


#Update-TSBootImageID
$UpdateTSBootImageIDSplat = @{
    SiteCode = "PS1" 
    ServerName = "cm01.asd.net" 
    OldBootImageID = "PS1000001" 
    NewBootImageID = "PS1000002"
}

.\Update-TSBootImageID.ps1 @UpdateTSBootImageIDSplat

$ServiceWIMSplat = @{
    OSName = "Windows 10 Enterprise"
    OSVersion = "1909"
    OSArch = "x64"
    Month = "2019-11"
    RootFolder = "C:\ImageServicing"
    SCCMServer = "CPRTHQ-CCM01.cpchem.net"
    SiteCode = "CRT"
    DISMPath = "Dism.exe"
    CreateProdMedia = $true
    ApplyDynamicUpdates = $true
    Cleanup = $false
    Optimize = $false
    RemoveInBoxApps = $true
}

.\Sevice-WIM.ps1 @ServiceWIMSplat