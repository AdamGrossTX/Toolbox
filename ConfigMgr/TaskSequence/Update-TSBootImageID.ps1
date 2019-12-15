<#
.SYNOPSIS
    Bulk Update the BootImageID for Task Sequences in ConfigMgr
.DESCRIPTION
    Bulk Update the BootImageID for Task Sequences in ConfigMgr
.PARAMETER SiteCode
    ConfigMgr Site Code
.PARAMETER SiteServer
    ConfigMgr Site Server Name
.PARAMETER OldBootImageID
    ID of the current boot image that is being replaced
.PARAMETER NewBootImageID
    ID of the new boot image

.NOTES
  Version:          1.0
  Author:           Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:    12/14/2019
  
.EXAMPLE
    Update BootImageID
    .\Update-TSBootImageID.ps1 $SiteCode "PS1" -ServerName "cm01.asd.net" -OldBootImageID "PS1000001" -NewBootImageID "PS1000002"

.EXAMPLE
    Update BootImageID with Splatting
    $UpdateTSBootImageIDSplat = @{
        SiteCode = "PS1" 
        ServerName = "cm01.asd.net" 
        OldBootImageID = "PS1000001" 
        NewBootImageID = "PS1000002"
    }

    .\Update-TSBootImageID.ps1 $UpdateTSBootImageIDSplat

 #>

[cmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    $SiteCode,
    
    [Parameter(Mandatory=$true)]
    [string]
    $ServerName,
    
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
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ServerName @initParams
}
Set-Location "$($SiteCode):\" @initParams

#######################################################

$TSList = Get-CMTaskSequence | Where-Object BootImageId -eq $OldBootImageID

Write-Host "Updating the Boot Image on $($TSList.Count) Task Sequences from $($OldBootImageID) to $($NewBootImageID)"

$Count = 0
ForEach ($TS in $TSList)
{
    $Count ++
    Write-Host "#############################"
    Write-Host "Processing Record $($Count) of $($TSList.Count): $($TS.Name)"
    $TS | Set-CMTaskSequence -BootImageId $NewBootImageID
    Write-Host "Updated: $($TS.Name)"
}