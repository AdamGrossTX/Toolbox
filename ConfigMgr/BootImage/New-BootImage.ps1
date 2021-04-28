<#
.SYNOPSIS
    Creates a new ConfigMgr Boot Image
.DESCRIPTION
    Creates a new ConfigMgr Boot Image
.PARAMETER SiteCode
    ConfigMgr Site Code
.PARAMETER SiteServer
    ConfigMgr Site Server Name
.PARAMETER BootImageRoot
    Root folder where the script will create a new folder for your boot image
.PARAMETER OSArch
    x86 or x64
.PARAMETER BootImageFolderName
    The name for the new folder that will be created for your boot image
.PARAMETER SourceWIM
    OPTIONAL - The path to the source WIM file that you will use instead of the default WinPE WIM
.PARAMETER BootImageName
    The name of the BootImage that will be displayed in the ConfigMgr Console
.PARAMETER BootImageDescription
    The description of the boot image in the ConfigMgr console
.PARAMETER DPGroupName
    The name of the Distribution Point Group to distribute the boot image to
.PARAMETER DriverCategoryName
    OPTIONAL - Category Name from drivers in the Driver Repository that will be included in the boot image
.PARAMETER PrestartCommandLine
    OPTIONAL - Commandline for the prestart command
.PARAMETER PrestartIncludeFilesDirectory
    OPTIONAL - Path to the pre-start folder to be used for pre-start command file content. Uses Pre-Start by default
.PARAMETER ConsoleFolderPath
    OPTIONAL - The path to the console folder to move the boot image to.

.NOTES
  Version:          1.0
  Author:           Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:    12/14/2019
    
  Reference
  #https://docs.microsoft.com/en-us/powershell/module/configurationmanager/set-cmbootimage?view=sccm-ps


.EXAMPLE
    Create new boot image
    New-BootImage.ps1 -SiteCode = "PS1" -SiteServer = "CM01.asd.net" -OSArch = "x64" -BootImageRoot = "\\cm01\Media\BootImages" -BootImageFolderName = "WinPE10x64-ADK1903-$(Get-Date -Format yyyyMMdd)" -BootImageName = "Prod - Boot Image $(Get-Date -Format yyyyMMdd)" -BootImageDescription = "ADK 1903 $(Get-Date -Format yyyyMMdd)" -DPGroupName = "All Distribution Points" -DriverCategoryName = "WinPE" -PrestartCommandLine = "Custom.cmd" -ConsoleFolderPath = "\Production Boot Images" 

.EXAMPLE
    Using Splatting:
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

#>
 

[cmdletBinding()]
param(
[Parameter(Mandatory=$True, ValueFromPipelineByPropertyName = $True, Position=1)]
[string]
$SiteServer,

[Parameter(Mandatory=$True, ValueFromPipelineByPropertyName = $True, Position=2)]
[string]
$SiteCode,

[Parameter(Mandatory=$False, ValueFromPipelineByPropertyName = $True, Position=4)]
[ValidateSet ('x64', 'x86')]
[string]
$OSArch = "x64",

[Parameter(Mandatory=$True, ValueFromPipelineByPropertyName = $True, Position=3)]
[string]
$BootImageRoot,

[Parameter(Mandatory=$True, ValueFromPipelineByPropertyName = $True, Position=5)]
[string]
$BootImageFolderName,

[Parameter(Mandatory=$False, ValueFromPipelineByPropertyName = $True, Position=6)]
[string]
$SourceWIM,

[Parameter(Mandatory=$True, ValueFromPipelineByPropertyName = $True, Position=7)]
[string]
$BootImageName,

[Parameter(Mandatory=$False, ValueFromPipelineByPropertyName = $True, Position=8)]
[string]
$BootImageDescription,

[Parameter(Mandatory=$True, ValueFromPipelineByPropertyName = $True, Position=9)]
[string]
$DPGroupName,

[Parameter(Mandatory=$False, ValueFromPipelineByPropertyName = $True, Position=10)]
[string]
$DriverCategoryName,

[Parameter(Mandatory=$False, ValueFromPipelineByPropertyName = $True, Position=11)]
[string]
$PrestartCommandLine,

[Parameter(Mandatory=$False, ValueFromPipelineByPropertyName = $True, Position=12)]
[string]
$PrestartIncludeFilesDirectory,

[Parameter(Mandatory=$False, ValueFromPipelineByPropertyName = $True, Position=13)]
[string]
$ConsoleFolderPath

)

If(!($SourceWIM)) {
    
    $ADKArch = Switch($OSArch) {
        "x64" {"amd64"; break;}
        default {$OSArch};
    }
    
    $SourceWIM = "\\{0}\c$\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\{1}\en-us\winpe.wim" -f $SiteServer, $ADKArch
}

$NewWIMPath = Join-Path -Path $BootImageRoot -ChildPath $BootImageFolderName
If (!($PrestartIncludeFilesDirectory)) {
    $PrestartIncludeFilesDirectory = Join-Path -Path $BootImageRoot -ChildPath "Pre-Start"
}

If(Test-Path $NewWIMPath) {
    Write-Host "NewWIMPath already exists $($NewWIMPath)"
}
Else {
    New-Item -Path $NewWIMPath -ItemType Directory
}

If(Test-Path $PrestartIncludeFilesDirectory) {
    Copy-Item -Path $PrestartIncludeFilesDirectory -Destination $NewWIMPath -Recurse
}

If(Test-Path $SourceWIM -ErrorAction Continue) {
    Copy-Item -Path $SourceWIM -Destination $NewWIMPath -Force
}

$initParams = @{}
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer @initParams
}

Set-Location "$($SiteCode):\" @initParams

If(!(Get-CMBootImage -Name $BootImageName)) {
    $BootImage = New-CMBootImage -Name $BootImageName -Path "$($NewWIMPath)\winpe.wim" -Index 1
}
Else {
    $BootImage = Get-CMBootImage -Name $BootImageName
}

If($DriverCategoryName) {
    $Categories = Get-CMCategory | Where-Object LocalizedCategoryInstanceName -eq $DriverCategoryName
    $WinPEDrivers = Get-CMDriver | Where-Object {$_.CategoryInstance_UniqueIDs -eq $Categories.CategoryInstance_UniqueID}
    ForEach ($Driver in $WinPEDrivers) {
        Set-CMDriverBootImage -SetDriveBootImageAction AddDriverToBootImage -BootImage $BootImage -Driver $Driver
    }
}

$OptionalComponents = Get-CMWinPEOptionalComponentInfo -Architecture $OSArch -LanguageId 1033 | Where-Object {$_.Name -in ("WinPE-PowerShell","WinPE-Dot3Svc","WinPE-DismCmdlets")}
$BootImageOptions = @{
    DeployFromPxeDistributionPoint = $True
    EnableCommandSupport = $True 
    AddOptionalComponent = $OptionalComponents
    PrestartCommandLine = $PrestartCommandLine 
    PrestartIncludeFilesDirectory = $PrestartIncludeFilesDirectory
    EnableBinaryDeltaReplication = $True
    Priority = 'High'
    ScratchSpace = 512
}

$BootImage | Set-CMBootImage @BootImageOptions
If($DPGroupName) {
    $BootImage | Start-CMContentDistribution -DistributionPointGroupName $DPGroupName
    $BootImage | Update-CMDistributionPoint -ReloadBootImage
}

If($ConsoleFolderPath) {
    $BootImage | Move-CMObject -FolderPath "$($SiteCode):\BootImage$($ConsoleFolderPath)"
}