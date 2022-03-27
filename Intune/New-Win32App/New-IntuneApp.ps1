[cmdletbinding()]
param (
    [uri]$IntuneWinUtilPath = "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/master/IntuneWinAppUtil.exe",
    $SourceRoot = "\\MyShare\Intune",
    $SourceFolderName = "Remove-TeamsHomeApp",
    $SetupFileName = "Remove-TeamsHomeApp.ps1",
    $OutputRoot = "\\MyShare\Intune"
)
function New-IntuneWinFile {
    [cmdletbinding()]
    param (
        [string]$SetupFolder,
        [string]$SourceSetupFile,
        [string]$OutputFolder,
        [switch]$Silent
    )

    #download latest intunewinutility
    $IntuneWinUtilName = $IntuneWinUtilPath.Segments[$IntuneWinUtilPath.Segments.Count-1]
    Invoke-WebRequest -Uri $IntuneWinUtilPath -OutFile "$($env:TEMP)\$($IntuneWinUtilName)"
    
    $IntuneWinArgs = New-Object -TypeName "System.Collections.ArrayList"
    $IntuneWinArgs.Add("-c `"$($SetupFolder)`"")
    $IntuneWinArgs.Add("-s `"$($SourceSetupFile)`"")
    $IntuneWinArgs.Add("-o `"$($OutputFolder)`"")
    if($Silent.IsPresent) {
        $IntuneWinArgs.Add("-q")
    }

    $Result = Start-Process -FilePath "$($env:TEMP)\$($IntuneWinUtilName)" -ArgumentList $IntuneWinArgs -PassThru
    Return $Result
}


$NewIntuneWinSplat = @{
    SetupFolder =  "$($SourceRoot)\$($SourceFolderName)"
    SourceSetupFile = $SetupFileName
    OutputFolder = "$($OutputRoot)\$($SourceFolderName)"
    Silent = $True
}

New-IntuneWinFile @NewIntuneWinSplat