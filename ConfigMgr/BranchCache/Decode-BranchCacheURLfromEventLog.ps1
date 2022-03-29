#Find EventId 13 in the Microsoft-Windows-BranchCache/Operational event log.
#Copy the value from ContentId to $val. Do not include the leading 0x if it exists
#Stolen from Johan Arwidmark - https://github.com/AdamGrossTX/DRFiles/blob/master/Scripts/BranchCache/Get-BranchCacheError13FileList.ps1
[string[]]$encodedURLs = @()

$decodedURLs = 
    foreach($url in $encodedURLs) {
        $url = $url.Replace("0x")
        -join (
        $url | Select-String ".." -AllMatches | 
        ForEach-Object Matches | 

            ForEach-Object {
            If ([string]$_ -eq "00") {}
            Else{[char]+"0x$_"}
            }
        )
    }
$decodedURLs