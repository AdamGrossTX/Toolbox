#This code isn't great. Needs more work. But good starting point.
$TargetDevices = @(
)

ForEach($TargetDevice in $TargetDevices) {
    Copy-Item "$($PSScriptRoot)\New-CertReq.ps1","$($PSScriptRoot)\Run-NewCertReq.ps1" -Destination "\\$($TargetDevice)\c$\Temp" -Container -Force
    $Session = Enter-PSSession -ComputerName $TargetDevice -EnableNetworkAccess
    Invoke-Command -ComputerName $TargetDevice -FilePath "C:\Temp\Run-NewCertReq.ps1" -Credential (Get-Credential)
    Exit-PSSession

}