
[cmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    $SiteCode,
    
    [Parameter(Mandatory=$true)]
    [string]
    $ProviderMachineName,

    [Parameter(Mandatory=$true)]
    [string]
    $ClientVersion = "5.00.8790.1007"
)

$initParams = @{}
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}
Set-Location "$($SiteCode):\" @initParams


$ClientIDList = @{}
$ClientIDList[""] = ''
$ClientIDList[""] = ''
$ClientIDList[""] = ''

$ClientSource = '\\SERVER\SCCMClient$'
$ServerPackage = Get-CMPackage -Id $ClientIDList["ServerClient"]
Set-Location "c:\"
Get-ChildItem -Path $ServerPackage.PkgSourcePath | Remove-Item -Recurse
Copy-Item -Path "$($ClientSource)\*" -Destination $ServerPackage.PkgSourcePath -Recurse -Force

Set-Location "$($SiteCode):\" @initParams
$Count = 0
ForEach($key in $ClientIDList.Keys)
{
    $Count ++
    Write-Host "#############################"
    Write-Host "Processing Record $($Count) of $($ClientIDList.Count): $($Key)"
    Get-CMPackage -ID $ClientIDList[$key] | Set-CMPackage -Version $ClientVersion
    Update-CMDistributionPoint -PackageId $ClientIDList[$key]
    Write-Host "Updated: $($Key)"
}