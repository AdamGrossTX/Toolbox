try {
    $UWFNameSpace = "root\standardcimv2\embedded"
    $UWF = Get-CIMInstance -Namespace $UWFNameSpace -ClassName UWF_Filter -ErrorAction SilentlyContinue

    if ($UWF.CurrentEnabled -eq $true) {
        Write-Host "UWF Enabled"
        Exit 0
    }
    else {
        Write-Warning "UWF Not Enabled"
        Exit 1
    }
}
catch {
    throw $_
}