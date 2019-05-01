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
    $OldBootImageID,

    [Parameter(Mandatory=$true)]
    [string]
    $NewBootImageID
)

$initParams = @{}
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}
Set-Location "$($SiteCode):\" @initParams

#######################################################

$TSList = Get-CMTaskSequence | Where-Object BootImageId -eq $OldBootImageID

Write-Host "Updating the Boot Image on $($TSList.Count) Task Sequnces from $($OldBootImageID) to $($NewBootImageID)"

$Count = 0
ForEach ($TS in $TSList)
{
    $Count ++
    Write-Host "#############################"
    Write-Host "Processing Record $($Count) of $($TSList.Count): $($TS.Name)"
    $TS | Set-CMTaskSequence -BootImageId $NewBootImageID
    Write-Host "Updated: $($TS.Name)"
}

#CRT00FAC
#CRT0101E