<#
.NOTES
    Author:           Adam Gross - @AdamGrossTX
    GitHub:           https://www.github.com/AdamGrossTX
    WebSite:          https://www.asquaredozen.com

#>
$GroupsPath = ".\Intune\Groups"
$RulesPath = ".\Intune\Rules"
$OutputPath = ".\GPO"
$DFSPath = "\\DFS01\DeviceControl"

$AllRules = @{
    "Silently Block All Mobile Phone Devices" = "492a1994-8e0d-426e-8800-e717d5badc97"
    "Allow All Removable Devices" = "5f1dfdc6-05f8-43b7-828b-39b76b74b347"
    "Allow Read Access for Cameras" = "b395c7ac-5fbf-41e9-a5fd-52e23167b143"
    "Block All Removable Devices" = "bddfbc76-7f03-490e-9433-67774831c770"
}

$AllGroups = @{
    "CDROM Devices" = "2994483d-64d6-44f2-a95c-63b905298dae"
    "Cameras" = "2a93d745-7ff4-4667-a384-a57b84344ff0"
    "Mobile Phone Devices" = "3551c70b-349b-4e2a-bd3e-a5687d94a22c"
    "Peripherals" = "3cb15697-09a3-4f0d-872c-691b6b377e71"
    "All Removable Devices" = "6f34e099-573d-4fd9-b6ac-eb8650d7d99b"
    "WPD Devices" = "ad32c4e8-981a-43e1-bf2c-496fa176256c"
    "Removable Media Devices" = "cad1615e-e5d6-4c11-94aa-2df05861a372"
}

$ProdRules = @(
    "Block All Removable Devices",
    "Allow Read Access for Cameras",
    "Silently Block All Mobile Phone Devices"
)

$RulesFile = New-Item -Path "$($OutputPath)\DeviceControlRules.XML" -Force
$RulesFile | Add-Content -Value "<PolicyRules>"
foreach($Rule in $ProdRules) {
    $RulesFile | Add-Content -Value (Get-Content -Path "$($RulesPath)\$($AllRules[$Rule]).xml" -Raw).ToString()
}
$RulesFile | Add-Content -Value "</PolicyRules>"

$GroupsFile = New-Item -Path "$($OutputPath)\DeviceControlGroups.XML" -Force
$GroupsFile | Add-Content -Value "<Groups>"
foreach($Group in $AllGroups.Keys) {
    $GroupsFile | Add-Content -Value (Get-Content -Path "$($GroupsPath)\$($AllGroups[$Group]).xml" -Raw).ToString()
}
$GroupsFile | Add-Content -Value "</Groups>"

Get-ChildItem -Path $OutputPath | Copy-Item -Destination $DFSPath -Force