<#
.SYNOPSIS
    Imports Windows Image into ConfigMgr
.DESCRIPTION
    Imports Windows Image into ConfigMgr
.PARAMETER SiteCode
    ConfigMgr Site Code
.PARAMETER SiteServer
    ConfigMgr Site Server Name
.PARAMETER DPGroupName
    The name of the Distribution Point Group to distribute the boot image to
.PARAMETER ConsoleFolderPath
    OPTIONAL - The path to the console folder to move the boot image to.
.PARAMETER DestinationRootPath
    The path to the root folder where the new media will be copied
.PARAMETER SourceMediaRootPath
    The path to the source media
.PARAMETER OSVersion
    Windows OS Version
.PARAMETER OSArch
    Windows OS Architecture x86 or x64 or ARM64
.PARAMETER Month
    The the month in YYYY-MM format
.PARAMETER ImageType
    Specify if importing install Install WIM for new installs or Upgrade media for upgrades or both.

.NOTES
  Version:          1.0
  Author:           Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:    12/14/2019
  
.EXAMPLE
    Import new or serviced Windows Media
    .\Import-WindowsImage.ps1 .\Import-WindowsImage $SiteCode "PS1" -ServerName "cm01.asd.net" -DPGroupName "All Distribution Points" -ConsoleFolderPath "\Windows 10" -DestinationRootPath "\\sources\OSInstallFiles\Windows 10" -CompletedMediaRootPath "C:\ImageServicing\CompletedMedia" -OSVersion "1909" -OSArch "x64"  -Month "2019-12" -ImageType "Both"

.EXAMPLE
    Import new or serviced Windows Media Using Splatting:
    $ImportWindowsImageSplat = @{
        SiteCode = "PS1"
        ServerName = "cm01.asd.net"
        DPGroupName = "All Distribution Points"
        ConsoleFolderPath = "\Windows 10"
        DestinationRootPath = "\\sources\OSInstallFiles\Windows 10"
        CompletedMediaRootPath = "C:\ImageServicing\CompletedMedia"
        OSVersion = "1909"
        OSArch = "x64" 
        Month = "2019-12"
        ImageType = "Both"
    }

    .\Import-WindowsImage.ps1 $ImportWindowsImageSplat

 #>
 


 [cmdletBinding()]
 param(
     [Parameter(Mandatory=$False)]
     [string]
     $SiteCode,
     
     [Parameter(Mandatory=$False)]
     [string]
     $ServerName,
     
     [Parameter(Mandatory=$False)]
     [string]
     $DestinationRootPath,
 
     [Parameter(Mandatory=$False)]
     [string]
     $SourceMediaRootPath,
 
     [Parameter(Mandatory=$False,HelpMessage="Operating System version to service. Default is 1903.")]
     [ValidateSet('1709','1803','1809','1903','1909')]
     [string]
     $OSVersion,
 
     [Parameter(Mandatory=$False,HelpMessage="Architecture version to service. Default is x64.")]
     [ValidateSet ('x64','x86','ARM64')]
     [string]
     $OSArch,
 
     [Parameter(Mandatory=$False,HelpMessage="Year-Month of updates to apply (Format YYYY-MM).")]
     [ValidatePattern("\d{4}-\d{2}")]
     [string]
     $Month,
 
     [Parameter(Mandatory=$False)]
     [ValidateSet("Install","Upgrade", "Both")]
     $ImageType,
 
     [Parameter(Mandatory=$False)]
     [string]
     $ConsoleFolderPath,
 
     [Parameter(Mandatory=$False)]
     [string]
     $DPGroupName
 )
 
 Try {
     #region Copy Compelted Media to SCCM Source Folder
     Write-Host "Copying Completed Media to SCCM Source Folder"
     
     $CompletedMediaPath = Join-Path -Path $SourceMediaRootPath -ChildPath "$($OSVersion)\$($Month)"
     $DestinationPath = Join-Path -Path $DestinationRootPath -ChildPath "$($OSVersion)\$($Month)"
     
     $OSMediaPath = Join-Path -Path $DestinationPath -ChildPath "$($OSArch)"
     $WIMPath = Join-Path -Path $OSMediaPath -ChildPath "\sources\install.wim"
     
     Write-Host "Copying Completed Media to SCCM Source Folder"
     Write-Host "Source Path: $($CompletedMediaPath)"
     Write-Host "Source Path: $($DestinationPath)"
     
     Copy-Item -Path $CompletedMediaPath -Destination $DestinationPath -Container -Recurse
     $WIMInfo = Get-WindowsImage -ImagePath $WIMPath -Index 1
     
     Write-Host "Copy Completed"
     #endregion
     
     #region Connect to SCCM
     $initParams = @{}
     if((Get-Module ConfigurationManager) -eq $null) {
         Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
     }
     
     if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
         New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ServerName @initParams
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
     
     If($ImageType -eq 'Install' -or $ImageType -eq 'Both') {
         Write-Host "Importing new OS Image"
         $OS = New-CMOperatingSystemImage -Name $ImageName -Version $WIMInfo.Version -Path $WIMPath -Description $ImageName
         Write-Host "Updating OS Image Properties"
         $OS | Set-CMOperatingSystemImage -EnableBinaryDeltaReplication:$True -Priority High 
         If($ConsoleFolderPath) {
             Write-Host "Moving OS Image to correct console folder"
             $OS | Move-CMObject -FolderPath "$($SiteCode):\OperatingSystemImage$($ConsoleFolderPath)"
         }
         If($DPGroupName) {
             Write-Host "Starting OS Image content distribution"
             $OS | Start-CMContentDistribution -DistributionPointGroupName $DPGroupName
             
         }
     }
 
     If($ImageType -eq 'Upgrade' -or $ImageType -eq 'Both') {
         Write-Host "Importing new OS Upgrade Media"
         $OSUpgrade = New-CMOperatingSystemUpgradePackage -Name "$($ImageName) - UPG" -Version $WIMInfo.Version -Path $OSMediaPath -Description "$($ImageName) Upgrade"
         Write-Host "Updating OS Upgrade Media Properties"
         $OSUpgrade | Set-CMOperatingSystemInstaller -EnableBinaryDeltaReplication:$true -Priority High
         If($ConsoleFolderPath) {
             Write-Host "Moving OS Upgrade to correct console folder"
             $OSUpgrade | Move-CMObject -FolderPath "$($SiteCode):\OperatingSystemInstaller$($ConsoleFolderPath)"
         }
         If($DPGroupName) {
             Write-Host "Starting OS Upgrade Media content distribution"
             $OSUpgrade | Start-CMContentDistribution -DistributionPointGroupName $DPGroupName
         }
     }
 
 }
 Catch {
     Write-Host "An error occurred."
     $Error[0]
 }
