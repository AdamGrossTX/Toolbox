#Run this in CMPivot
<#

WinEvent('Microsoft-Windows-BranchCache/Operational',1d)
| where ID == 13
| project Device, DateTime, ID, Message

#>
#Export to CSV and save to C:\BCTest\FileList\CMPivotBCErrors.csv

$Content = Get-Content -Path C:\BCTest\FileList\CMPivotBCErrors.csv -Raw | ConvertFrom-CSV

$EntryObjs = foreach($entry in $Content) {
    [regex]$errorRegex = '(?<MessagePrefix>.+)(?>0x)(?<encodedURL>.*?)(?> )(?<MessageSuffix>(.|\n)*)'
    $entry.Message -match $errorRegex | out-null
    $decodedURL = 
            -join (
            $matches.encodedURL | Select-String ".." -AllMatches | 
            ForEach-Object Matches | 
                ForEach-Object {
                If ([string]$_ -eq "00") {}
                Else{[char]+"0x$_"}
                }
            )
    [PSCustomObject]@{
        DeviceName = $entry.Device
        DateTime = $entry.DateTime
        ID = $entry.ID
        #Message = $entry.Message
        #EncodedURL = $matches.encodedURL
        DecodedURL = $decodedURL
        MessagePrefix = $matches.MessagePrefix
        MessageSuffix = $matches.MessageSuffix
    }
}

$EntryObjs