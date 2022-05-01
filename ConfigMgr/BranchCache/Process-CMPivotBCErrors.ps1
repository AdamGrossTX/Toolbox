<#
.SYNOPSIS
    decodes URL with BranchCache Error 13 returned by CMPivot

  Version:          1.0
  Author:           Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:    03/27/2022
    
#Run this in CMPivot
<#

WinEvent('Microsoft-Windows-BranchCache/Operational',1d)
| where ID == 13
| project Device, DateTime, ID, Message

#>
#Export to CSV and save to $SourceFilePath\CMPivotResults\*.csv

param (
    [string]$SourceFilePath = "C:\BCTest"
)

$script:tick = " " + [char]0x221a
$CMPivotSource = "$($SourceFilePath)\CMPivotResults"
$ExportFile = "$($SourceFilePath)\FileList\CMPivotBCEntries_$(Get-Date -Format yyyyhhMM_HHmmss).CSV"

New-Item -Path $CMPivotSource -ItemType Directory -Force | Out-Null

if (Test-Path "$($CMPivotSource)\*.csv") {
    $Content = Get-ChildItem -Path $CMPivotSource | Get-Content -raw | ConvertFrom-CSV
    if ($Content) {
        $EntryObjs = foreach ($entry in $Content) {
            [regex]$errorRegex = '(?<MessagePrefix>.+)(?>: 0x)(?<encodedURL>.+?(?> ))(?<MessageSuffix>(.*)).+\nError: (?<ErrorNumber>\d+?)( )(?<ErrorMessage>.+)\s+(?<ErrorAction>.+)'
            $entry.Message -match $errorRegex | out-null
            if ($matches) {
                $decodedURL = 
                -join (
                    $matches.encodedURL | Select-String ".." -AllMatches | 
                    ForEach-Object Matches | 
                    ForEach-Object {
                        If ([string]$_ -eq "00") {}
                        Else { [char] + "0x$_" }
                    }
                )
                [PSCustomObject]@{
                    DeviceName    = $entry.Device
                    DateTime      = $entry.DateTime
                    ID            = $entry.ID
                    #Message = $entry.Message
                    #EncodedURL = $matches.encodedURL
                    URL           = $decodedURL
                    MessagePrefix = $matches.MessagePrefix
                    MessageSuffix = $matches.MessageSuffix
                    ErrorMessage  = $matches.ErrorMessage
                    ErrorAction   = $matches.ErrorAction.Replace("`"", "")
                    ErrorNumber   = $matches.ErrorNumber
                }
            }
            else {
                [PSCustomObject]@{
                    DeviceName    = $entry.Device
                    DateTime      = $entry.DateTime
                    ID            = $entry.ID
                    #Message = $entry.Message
                    #EncodedURL = $matches.encodedURL
                    URL           = $null
                    MessagePrefix = $null
                    MessageSuffix = $null
                    ErrorMessage  = $null
                    ErrorAction   = $null
                    ErrorNumber   = $null
                }
            }
        }

        $EntryObjs | Export-Csv -Path $ExportFile -Force
        Write-Host "Results output to $($ExportFile)"
    }
    else {
        Write-Host "No content found."
    }
}
else {
    Write-Host "No CSV File Found."
}
