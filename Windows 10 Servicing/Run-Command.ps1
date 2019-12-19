$ServiceWIMSplat = @{
    ServerName = ""
    SiteCode = ""
    OSVersion = "1909"
    Cleanup = $False
    KillAV = $True
}

[PSCustomObject]$ServiceWIMSplat | .\Service-WIM.ps1