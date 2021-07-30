#https://www.maximerastello.com/manually-re-enroll-a-co-managed-or-hybrid-azure-ad-join-windows-10-pc-to-microsoft-intune-without-loosing-current-configuration/

try {

$IntuneCertIssuer = "CN=Microsoft Intune MDM Device CA"
$AzureIssuer = "CN=MS-Organization-*Access*"

#region Get Tasks
$TaskPath = "\Microsoft\Windows\EnterpriseMgmt\"
$Tasks = Get-ScheduledTask -TaskPath "$($TaskPath)*" -ErrorAction SilentlyContinue

if($Tasks) {
    $PathParts = $Tasks[0].TaskPath.Split('\')
    $TaskGUID = $PathParts[$PathParts.Count-2]

    Write-Output "Deleting Scheduled Tasks"
    $Tasks | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

    if($TaskGUID) {
        Get-Item -Path "C:\Windows\System32\Tasks\$($TaskPath)$($TaskGUID)" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    }
}
#endregion

if($TaskGUID) {
$KeyList = @(
    "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments\$($TaskGuid)"
    "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments\Status\$($TaskGuid)"
    "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked\$($TaskGuid)"
    "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\AdmxInstalled\$($TaskGuid)"
    "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\Providers\$($TaskGuid)"
    "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\$($TaskGuid)"
    "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning\OMADM\Logger\$($TaskGuid)"
    "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning\OMADM\Sessions\$($TaskGuid)"
)

#region Get Intune Device Registration Info
$DMClientPath = "HKLM:\SOFTWARE\Microsoft\Enrollments\$($TaskGuid)\DMClient\MS DM Server"
$EntDMID = Get-ItemPropertyValue -Path $DMClientPath -Name "EntDMID" -ErrorAction SilentlyContinue
$EntDeviceName = Get-ItemPropertyValue -Path $DMClientPath -Name "EntDeviceName" -ErrorAction SilentlyContinue
#endregion

#region delete Intune Device Registrion registry keys
foreach($key in $KeyList) {
    $KeyInstance = Get-Item -Path Registry::$($Key) -ErrorAction SilentlyContinue
    if($KeyInstance) {
        $KeyInstance | Get-ChildItem -Recurse -ErrorAction Continue
        Write-Output "Removing: $($KeyInstance.Name)"
        $KeyInstance | Remove-Item -Force -Recurse -ErrorAction Continue
    }
}
}
#endregion

#region Cleanup Intune and Azure Certs
$IntuneCert = Get-ChildItem -Path "cert:\LocalMachine\My" | Where-Object {$_.Issuer -eq $IntuneCertIssuer}
if($IntuneCert) {
    $IntuneDeviceID = ($IntuneCert.SubjectName.Name.Split(',') | Where-Object {$_ -like 'CN=*'}).trim().Replace('CN=','')
    $IntuneCert | Remove-Item -Force -ErrorAction SilentlyContinue
}

$AzureCert = Get-ChildItem -Path "cert:\LocalMachine\My" | Where-Object {$_.Issuer -like $AzureIssuer}
if($AzureCert) {
    $AzureDeviceID = ($AzureCert.SubjectName.Name.Split(',') | Where-Object {$_ -like 'CN=*'}).trim().Replace('CN=','')
    $AzureCert | Remove-Item -Force -ErrorAction SilentlyContinue
}
#endregion

Write-Output "TaskGUID:         $($TaskGUID)"
Write-Output "AzureDeviceID:    $($AzureDeviceID)"
Write-Output "IntuneDeviceID:   $($IntuneDeviceID)"
Write-Output "EntDMID:          $($EntDMID)"
Write-Output "EntDeviceName:    $($EntDeviceName)"

$TaskGUID = $null
$AzureDeviceID = $null
$IntuneDeviceID = $null
$EntDMID = $null
$EntDeviceName = $null

}
catch {
    throw $_
}


#For Re-Provisioning
Get-ItemProperty -Path registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin" | Set-ItemProperty -Value 1 -Name "autoWorkplaceJoin" -Force
Get-ScheduledTask -TaskPath "\Microsoft\Windows\Workplace Join\" -ErrorAction SilentlyContinue | Enable-ScheduledTask -ErrorAction SilentlyContinue
# | Start-ScheduledTask

#Restart-service ccmexec

#Computer\HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\CloudDomainJoin\Diagnostics


