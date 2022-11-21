<#
.NOTES
    #Completely Uninstall Visual C++ Redistributables
    Author:           Adam Gross - @AdamGrossTX
    GitHub:           https://www.github.com/AdamGrossTX
    WebSite:          https://www.asquaredozen.com
#>

function Uninstall-Redist {
    param(
        [version]$TargetVersion,
        [string]$SourcePath = "$PSScriptRoot\$TargetVersion",
        [Parameter()]
        [ValidateSet("x64", "x86")]
        [string]$BitNess = "x64"
    )

    $Path = switch ($bitness) {
        "x64" { "$Env:SystemRoot\System32" }
        "x86" { "$Env:SystemRoot\SysWOW64" }
        Default { "$Env:SystemRoot\System32" }
    }

    try {
        Start-Process -FilePath "$SourcePath\vc_redist.$Bitness.exe" -ArgumentList "/uninstall", "/passive" -Wait
        $FileList = @(
            "$Path\concrt140.dll",
            "$Path\mfc140.dll",
            "$Path\mfc140chs.dll",
            "$Path\mfc140cht.dll",
            "$Path\mfc140deu.dll",
            "$Path\mfc140enu.dll",
            "$Path\mfc140esn.dll",
            "$Path\mfc140fra.dll",
            "$Path\mfc140ita.dll",
            "$Path\mfc140jpn.dll",
            "$Path\mfc140kor.dll",
            "$Path\mfc140rus.dll",
            "$Path\mfc140u.dll",
            "$Path\mfcm140.dll",
            "$Path\mfcm140u.dll",
            "$Path\msvcp140.dll",
            "$Path\msvcp140_1 .dll",
            "$Path\msvcp140_2.dll",
            "$Path\msvcp140_atomic_wait.dll",
            "$Path\msvcp140_codecvt_ids.dll",
            "$Path\vcamp140.dll",
            "$Path\vccorlib140.dll",
            "$Path\vcomp140.dll",
            "$Path\vcruntime140.dll",
            "$Path\vcruntime140_1.dll"
        )

        $TargetFiles = Get-Item -Path $FileList -ErrorAction SilentlyContinue | Where-Object { ([Version]$_.VersionInfo.ProductVersion).Major -ge $TargetVersion.Major -and ([Version]$_.VersionInfo.ProductVersion).Minor -ge $TargetVersion.Minor }
    
        Write-Output "$TargetFiles.Count left behind."
    
        if ($TargetFiles.Count -ge 1) {
            $TargetFiles | ForEach-Object { & "$PSScriptRoot\movefile64.exe" $_.FullName '""' /nobanner -AcceptEula }
            Write-Output "Files flagged for removal. Reboot Needed."
        }
    }
    catch {
        throw $_
    }
}
#################### 

Function Install-Redist {
    param(
        [version]$TargetVersion,
        [string]$SourcePath = "$PSScriptRoot\$TargetVersion",
        [Parameter()]
        [ValidateSet("x64", "x86")]
        [string]$BitNess = "x64"
    )

    $Path = switch ($bitness) {
        "x64" { "$Env:SystemRoot\System32" }
        "x86" { "$Env:SystemRoot\SysWOW64" }
        Default { "$Env:SystemRoot\System32" }
    }
    
    Start-Process -FilePath "$SourcePath\vc_redist.$Bitness.exe" -ArgumentList "/install", "/passive" -Wait
}

Uninstall-Redist -TargetVersion "14.34.31931.0" -SourcePath "$PSScriptRoot\$TargetVersion" -BitNess "x64"
Uninstall-Redist -TargetVersion "14.34.31931.0" -SourcePath "$PSScriptRoot\$TargetVersion" -BitNess "x86"

& Shutdown -r -t 0

Install-Redist -TargetVersion "14.32.31332.0" -SourcePath "$PSScriptRoot\$TargetVersion" -BitNess "x64"
Install-Redist -TargetVersion "14.32.31332.0" -SourcePath "$PSScriptRoot\$TargetVersion" -BitNess "x86"
