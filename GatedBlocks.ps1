
$Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags'
$AppCompatFlagsKeys = Get-ChildItem -Path $Path

$TargetVersionUpgradeExperienceIndicators = $AppCompatFlagsKeys | Where-Object {$_.PSChildName -eq 'TargetVersionUpgradeExperienceIndicators'} | Get-ChildItem

$GatedBlockKeys = $TargetVersionUpgradeExperienceIndicators | Where-Object {$_.Property -eq 'GatedBlockId'}

$Values = $GatedBlockKeys | Get-ItemProperty -Name GatedBlockId | Where-Object {$_.GatedBlockId -ne 'None'}

If($Values) {
    Write-Host "GatedBlockId = $($Values.GatedBlockId)"
    Write-Host "OSBuildTarged = $($Values.PSChildName)"
}
Else {
    "No Blocks Found"
}

Registry('HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\AppCompatFlags\\Appraiser\\GWX') | where Property == 'SdbEntries' and Value  != ''

Registry('HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\AppCompatFlags\\TargetVersionUpgradeExperienceIndicators\\*\\') | where Property == 'GatedBlockId' and Value != 'None'