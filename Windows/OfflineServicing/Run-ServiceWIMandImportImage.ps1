$ServerName = "CM01.ASD.NET"
$SiteCode = "PS1"
$OSVersion = "20H2"
$Month = "2021-01"
$OSArch = "x64"
$IgnoreTheseUpdates = @("")

$ServiceWIMSplat = @{
    ServerName = $ServerName
    SiteCode = $SiteCode
    OSVersion = $OSVersion
    Month = $Month
    Optimize = $False
    Cleanup = $False
    KillAV = [switch]::Present
    AutoDLUpdates = $True
    IgnoreTheseUpdates = $IgnoreTheseUpdates
}

.\Service-WIM.ps1 @ServiceWIMSplat
#>

#<#
##Import-WindowsImage
$ImportWindowsImageSplat = @{
    ServerName = $ServerName
    SiteCode = $SiteCode
    SourceMediaRootPath = "C:\ImageServicing\CompletedMedia"
    DestinationRootPath = "\\cm01.asd.net\sources$\OSInstallFiles\Windows 10"
    OSVersion = $OSVersion
    OSArch = $OSArch 
    Month = $Month
    ImageType = "Install"
    ConsoleFolderPath = "\Windows 10"
    DPGroupName = "All DPs"
}

.\Import-WindowsImage.ps1 @ImportWindowsImageSplat
#>