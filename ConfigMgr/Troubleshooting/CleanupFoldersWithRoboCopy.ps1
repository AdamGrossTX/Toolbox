[cmdletbinding()]
param(
    $incoming,
    $Folder = "{3DA228BE-34DA-49f4-A081-66465B077429}",
    $DestinationRoot = "C:\Windows\System32",
    [switch]$remediate #1 or 0
)

try {
    $DestPath = Join-Path -Path $DestinationRoot -ChildPath $Folder
    $DestinationFolder = Get-Item -Path $DestPath -ErrorAction SilentlyContinue
    if ($DestinationFolder) {
        $TempFolder = New-Item -Path "$($env:TEMP)\$($Folder)" -ItemType Directory -Force
        $StartCount = ($DestinationFolder | Get-ChildItem).Count
        if ($remediate.IsPresent -and $TempFolder) {
            & robocopy "$($TempFolder.FullName)" "$($DestinationFolder.FullName.ToString())" /mir /r:0 /w:0 /e | Out-Null
            $TempFolder | Remove-Item -Force #-ErrorAction SilentlyContinue
            $EndCount = ($DestinationFolder | Get-ChildItem).Count
            return $EndCount
        }
        else {
            return $StartCount
        }
    }
    else {
        return 0
    }
}
catch {
    throw $_
}
