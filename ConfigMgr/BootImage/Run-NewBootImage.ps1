$NewBootImageSplat = @{
    SiteCode = "PS1"
    SiteServer = "CM01.asd.net"
    OSArch = "x64"
    BootImageRoot = "\\cm01\Media\BootImages"
    BootImageFolderName = "WinPE10x64-ADK1903-$(Get-Date -Format yyyyMMdd)"
    BootImageName = "Prod - Boot Image $(Get-Date -Format yyyyMMdd)"
    BootImageDescription = "ADK 1903 $(Get-Date -Format yyyyMMdd)"
    DPGroupName = "All Distribution Points"
    DriverCategoryName = "WinPE"
    PrestartCommandLine = "Custom.cmd"
    ConsoleFolderPath = "\Production Boot Images"
}

.\New-BootImage @NewBootImageSplat