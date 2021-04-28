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