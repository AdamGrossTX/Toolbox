#$Coll = Get-CMCollection -Name "Adams Machines"

$Coll.NamedValueDictionary

Get-CMDeviceCollection -Name "Adams Machines" | dir

$SiteCode = 'PS1'
$RootPath = -".\DeviceCollection"

$Folders = Get-ChildItem -Path $RootPath

ForEach($Folder in $Folders) {
    Get-ChildItem -Path "$($RootPath)\$($Folder.Name)"
}