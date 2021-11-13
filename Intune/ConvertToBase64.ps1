<#
.NOTES
    Author:           Adam Gross - @AdamGrossTX
    GitHub:           https://www.github.com/AdamGrossTX
    WebSite:          https://www.asquaredozen.com

#>

Param (
    [System.IO.FileInfo]
    $InputFile = ".\DefaultApps.XML"
)
[byte[]]$ContentAsBytes = [System.IO.File]::ReadAllBytes($Path)
[string]$b64 = [System.Convert]::ToBase64String($ContentAsBytes)
$b64 | Out-File -FilePath "$($InputFile.BaseName)_Base64.txt"