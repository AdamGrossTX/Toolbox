#https://docs.microsoft.com/en-us/powershell/module/configurationmanager/set-cmbootimage?view=sccm-ps

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
    $BootImageRoot = "", #"\\server\share\BootImageRoot"

    [Parameter(Mandatory=$false)]
    [string]
    $BootImageName = "", #Name for the boot image in the console
    
    [Parameter(Mandatory=$false)]
    [string]
    $BootWimName = "winpe.wim",
    
    [Parameter(Mandatory=$false)]
    [string]
    $BootImageFolderName = "", #"NewBootImage"
    
    [Parameter(Mandatory=$false)]
    [string]
    $BootImageDescription = "",

    [Parameter(Mandatory=$false)]
    [string]
    $DPGroupName = "",
    
    [Parameter(Mandatory=$false)]
    [string]
    $DriverCategoryName = "", #Admin category of drivers to inject

    [Parameter(Mandatory=$false)]
    [string]
    $PrestartCommandLine = "custom.cmd", #Prestart command
    
    [Parameter(Mandatory=$false)]
    [string]
    $PrestartIncludeFilesDirectory = "Pre-Start", #Name of folder in boot image folder with prestart files

    [Parameter(Mandatory=$false)]
    [string]
    $ConsoleFolderPath = "" #\Production Boot Images

)

$initParams = @{}
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

Set-Location "$($SiteCode):\" @initParams

if(!(Get-CMBootImage -Name $BootImageName)) {
    $BootImage = New-CMBootImage -Name $BootImageName -Path "$($BootImageRoot)\$($BootImageFolderName)\$($BootWimName)" -Index 1
}
Else {
    $BootImage = Get-CMBootImage -Name $BootImageName
}

$Categories = Get-CMCategory | Where-Object LocalizedCategoryInstanceName -eq $DriverCategoryName
$WinPEDrivers = Get-CMDriver | Where-Object {$_.CategoryInstance_UniqueIDs -eq $Categories.CategoryInstance_UniqueID}
ForEach ($Driver in $WinPEDrivers) {
    Set-CMDriverBootImage -SetDriveBootImageAction AddDriverToBootImage -BootImage $BootImage -Driver $Driver
}

$OptionalComponents = Get-CMWinPEOptionalComponentInfo -Architecture x64 -LanguageId 1033 | Where-Object {$_.Name -in ("WinPE-PowerShell","WinPE-Dot3Svc","WinPE-DismCmdlets")}
$BootImageOptions = @{
    DeployFromPxeDistributionPoint = $True
    EnableCommandSupport = $True 
    AddOptionalComponent = $OptionalComponents
    EnablePrestartCommand = $True 
    PrestartCommandLine = $PrestartCommandLine 
    IncludeFilesForPrestart = $True 
    PrestartIncludeFilesDirectory = $PrestartIncludeFilesDirectory
    EnableBinaryDeltaReplication = $True
    Priority = 'High'
    ScratchSpace = 512
}


$BootImage | Move-CMObject -FolderPath "$($SiteCode):\BootImage$($ConsoleFolderPath)"
$BootImage | Set-CMBootImage @BootImageOptions

$BootImage | Start-CMContentDistribution -DistributionPointGroupName $DPGroupName
$BootImage | Update-CMDistributionPoint -ReloadBootImage