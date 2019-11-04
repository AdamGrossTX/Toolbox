#This code shows 4 ways to Query and Update SCCM/WMI with PowerShell

$ServerName = "CMTP3-CM1.asd.lab"
$SiteCode = "TP3"
$NameSpace = "root\SMS\Site_{0}" -f $SiteCode
$ClassName = "SMS_UserMachineRelationship"
$MethodName = "CreateRelationship"
[uint32]$ResourceId = 16777219
[uint32]$WMISourceId = 2
[uint32]$CIMSourceId = 4
[uint32]$AdminSvcSourceId = 6
[uint32]$TypeId = 1
$UserAccountName = "ASD\Adam"

#region WMI
Get-WMIObject -Namespace $NameSpace -Class $ClassName | Format-Table
$Args = @($ResourceId,$WMISourceId,$TypeId,$UserAccountName)
Invoke-WmiMethod -Namespace $NameSpace -Class $ClassName -Name $MethodName -ArgumentList $Args | Select-Object StatusCode
#endregion

#region CIM
Get-CimInstance -Namespace $NameSpace -ClassName $ClassName | Format-Table
$Args = @{
    MachineResourceId = $ResourceId
    SourceId = $CIMSourceId
    TypeId = $TypeId
    UserAccountName = $UserAccountName
}
Invoke-CimMethod -Namespace $NameSpace -ClassName $ClassName -MethodName $MethodName -Arguments $Args | Select-Object ReturnValue
#endregion

#region AdminService 1910 TP
$GetURL = "https://{0}/AdminService/wmi/{1}" -f $ServerName,$ClassName
(Invoke-RestMethod -Method Get -Uri "$($GetURL)" -UseDefaultCredentials).Value | Format-Table

$PostURL = "https://{0}/AdminService/wmi/{1}.{2}" -f $ServerName,$ClassName,$MethodName
$Headers = @{
    "Content-Type" = "Application/json"
}
$Body = @{
        MachineResourceId = $ResourceId
        SourceId = $AdminSvcSourceId
        TypeId = 1
        UserAccountName = "$($UserAccountName)"
    } | ConvertTo-Json
    
Invoke-RestMethod -Method Post -Uri "$($PostURL)" -Body $Body -Headers $Headers -UseDefaultCredentials | Select-Object ReturnValue
#end region

#Region SCCM PS CmdLets
#This approach is most limited. 
$initParams = @{}
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ServerName @initParams
}
Set-Location "$($SiteCode):\" @initParams

Get-CMUserDeviceAffinity -UserName $UserAccountName | Format-Table
Add-CMDeviceAffinityToUser -UserName $UserAccountName -DeviceId $ResourceId

#endregion