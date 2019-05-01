
[cmdletBinding()]
param(
    [Parameter(Mandatory=$False)]
    [string]
    $SiteCode = "",
    
    [Parameter(Mandatory=$false)]
    [string]
    $ProviderMachineName = "",
    
    [Parameter(Mandatory=$false)]
    [string]
    $SourcePath = "",

    [Parameter(Mandatory=$false)]
    [string]
    $ImageName = "",
    
    [Parameter(Mandatory=$false)]
    [string]
    $DateCode = "2019-03",

    [Parameter(Mandatory=$false)]
    [string]
    $ImageVersion = "1803.17134.677",

    [Parameter(Mandatory=$false)]
    [string]
    $ImageDescription = "March 2019 Updates",

    [Parameter(Mandatory=$false)]
    [string]
    $DPGroupName = "",
    
    [Parameter(Mandatory=$false)]
    [string]
    $ConsoleFolderPath = "\Windows 10"

)

$initParams = @{}
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}
Set-Location "$($SiteCode):\" @initParams

$OS = New-CMOperatingSystemImage -Name "$($ImageName) - $($DateCode)" -Version $ImageVersion -Path "$($SourcePath)\Sources\install.wim" -Description $ImageDescription
$OSUpgrade = New-CMOperatingSystemUpgradePackage -Name "$($ImageName) - Upgrade - $($DateCode)" -Version $ImageVersion -Path $SourcePath -Description $ImageDescription

$OS | Set-CMOperatingSystemImage -EnableBinaryDeltaReplication:$True -Priority High
$OSUpgrade | Set-CMOperatingSystemInstaller -EnableBinaryDeltaReplication:$true -Priority High

$OS | Move-CMObject -FolderPath "$($SiteCode):\OperatingSystemImage$($ConsoleFolderPath)"
$OSUpgrade | Move-CMObject -FolderPath "$($SiteCode):\OperatingSystemInstaller$($ConsoleFolderPath)"

$OS | Start-CMContentDistribution -DistributionPointGroupName $DPGroupName
$OSUpgrade | Start-CMContentDistribution -DistributionPointGroupName $DPGroupName