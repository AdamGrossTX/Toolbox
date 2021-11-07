#This code shows 4 ways to Query and Update SCCM/WMI with PowerShell

$ServerName = "cm01.asd.net"
$SiteCode = "ps1"
$NameSpace = "root\SMS\Site_{0}" -f $SiteCode
$ClassName = "SMS_R_System"
[uint32]$ResourceId = 16777316
$UserAccountName = "ASD\Adam"

#WMI
Get-WMIObject -Namespace $NameSpace -Class $ClassName | Format-Table
#CIM
Get-CimInstance -Namespace $NameSpace -ClassName $ClassName | Format-Table

#AdminService
$GetURL = "https://cm01.asd.net/AdminService/wmi/SMS_R_System"
(Invoke-RestMethod -Method Get -Uri "$($GetURL)" -UseDefaultCredentials).Value | Format-Table

#ConfigMgr PS CmdLets
#This approach is most limited. 
$initParams = @{}
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ServerName @initParams
}
Set-Location "$($SiteCode):\" @initParams

Get-CMDevice | Format-Table

Get-CMUserDeviceAffinity -UserName $UserAccountName | Format-Table