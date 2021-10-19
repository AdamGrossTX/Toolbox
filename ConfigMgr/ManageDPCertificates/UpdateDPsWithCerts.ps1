$SiteCode = "ASD" # Site code 
$ProviderMachineName = "CM01.ASD.NET" # SMS Provider machine name
$initParams = @{}
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

Set-Location "$($SiteCode):\" @initParams

$myPwd = ConvertTo-SecureString -string "P@ssw0rd" -Force -AsPlainText
$TargetDevices = @(

)

ForEach($TargetDevice in $TargetDevices) {
    $DP = Get-CMDistributionPoint | Where-Object {$_.NalPath -match $TargetDevice}
    $DP | Set-CMDistributionPoint -CertificatePath "\\CM01.ASD.Net\DPCerts\$($TargetDevice)_DPCert.PFX" -CertificatePassword $myPwd
}
