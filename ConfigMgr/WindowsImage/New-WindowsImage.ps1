
[cmdletBinding()]
param(
    [Parameter(Mandatory=$False)]
    [string]
    $SiteCode = "PS1",
    
    [Parameter(Mandatory=$false)]
    [string]
    $ProviderMachineName = "cm01.asd.net",
    
    [Parameter(Mandatory=$false)]
    [string]
    $DPGroupName = "All Distribution Points",
    
    [Parameter(Mandatory=$false)]
    [string]
    $ConsoleFolderPath = "\Windows 10",

    [Parameter(Mandatory=$false)]
    [string]
    $DestinationRootPath = "\\sources\OSInstallFiles\Windows 10",

    [Parameter(Mandatory=$false)]
    [string]
    $CompletedMediaRootPath = "C:\ImageServicing\CompletedMedia",

    [Parameter(HelpMessage="Operating System version to service. Default is 1903.")]
    [ValidateSet('1709','1803','1809','1903','1909')]
    [string]
    $OSVersion = "1903",

    [Parameter(HelpMessage="Architecture version to service. Default is x64.")]
    [ValidateSet ('x64', 'x86','ARM64')]
    [string]
    $OSArch = "x64",   

    [Parameter(HelpMessage="Year-Month of updates to apply (Format YYYY-MM).")]
    [ValidatePattern("\d{4}-\d{2}")]
    [string]
    $Month = "2019-10"   

)

Try {
    #region Copy Compelted Media to SCCM Source Folder
    Write-Host "Copying Completed Media to SCCM Source Folder"
    
    $CompletedMediaPath = Join-Path -Path (Join-Path -Path $CompletedMediaRootPath -ChildPath $OSVersion) -ChildPath $Month
    $DestinationPath = Join-Path -Path $DestinationRootPath -ChildPath $OSVersion
    
    $OSMediaPath = Join-Path -Path $DestinationPath -ChildPath "$($Month)\$($OSArch)"
    $WIMPath = Join-Path -Path $OSMediaPath -ChildPath "\sources\install.wim"
    
    Write-Host "Copying Completed Media to SCCM Source Folder"
    Write-Host "Source Path: $($CompletedMediaPath)"
    Write-Host "Source Path: $($DestinationPath)"
    
    #Copy-Item -Path $CompletedMediaPath -Destination $DestinationPath -Container -Recurse
    $WIMInfo = Get-WindowsImage -ImagePath $WIMPath -Index 1
    
    Write-Host "Copy Completed"
    #endregion
    
    #region Connect to SCCM
    $initParams = @{}
    if((Get-Module ConfigurationManager) -eq $null) {
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
    }
    
    if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
        New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
    }
    Set-Location "$($SiteCode):\" @initParams
    #endregion
    
    $Arch = @{
        0 = "x86"
        5 = "arm"
        9 = "x64"
        6 ="ia64"
        11 = "neutral"
    }
    
    $ImageName = "$($WIMInfo.ImageName) - $($Arch[[int]$WIMInfo.Architecture]) - $($Month) - $($OSVersion)"
    
    Write-Host "Importing new OS Image"
    $OS = New-CMOperatingSystemImage -Name $ImageName -Version $WIMInfo.Version -Path $WIMPath -Description $ImageName
    Write-Host "Importing new OS Upgrade Media"
    $OSUpgrade = New-CMOperatingSystemUpgradePackage -Name "$($ImageName) - UPG" -Version $WIMInfo.Version -Path $OSMediaPath -Description "$($ImageName) Upgrade"
    
    Write-Host "Updating OS Image Properties"
    $OS | Set-CMOperatingSystemImage -EnableBinaryDeltaReplication:$True -Priority High 
    Write-Host "Updating OS Upgrade Media Properties"
    $OSUpgrade | Set-CMOperatingSystemInstaller -EnableBinaryDeltaReplication:$true -Priority High
    
    Write-Host "Moving OS Image to correct console folder"
    $OS | Move-CMObject -FolderPath "$($SiteCode):\OperatingSystemImage$($ConsoleFolderPath)"
    Write-Host "Moving OS Upgrade to correct console folder"
    $OSUpgrade | Move-CMObject -FolderPath "$($SiteCode):\OperatingSystemInstaller$($ConsoleFolderPath)"
    
    Write-Host "Starting OS Image content distribution"
    $OS | Start-CMContentDistribution -DistributionPointGroupName $DPGroupName
    Write-Host "Starting OS Upgrade Media content distribution"
    $OSUpgrade | Start-CMContentDistribution -DistributionPointGroupName $DPGroupName
    
    }
    Catch {
        Write-Host "An error occurred."
        $Error[0]
    }