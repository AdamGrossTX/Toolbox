<#
.SYNOPSIS
    tests BITS downloads to fins errors with BranchCache Content.

  Version:          1.0
  Author:           Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:    12/14/2019
    
# Relies on script stolen from Johan Arwidmark
# https://github.com/DeploymentResearch/DRFiles/tree/master/Scripts/BranchCache
# Run Get-BranchCacheError13FileList.ps1
# Save Output to C:\BCTest\FileList (ore than one CSV file can be saved here)
# NOTE - If the impacted content is coming from MCC, this script doesn't work and I haven't sorted out why yet.

#>
[cmdletbinding()]
param(
    $Creds = (Get-Credential),
    [string]$SourceFilePath = "C:\BCTest"
)

$script:tick    = " " + [char]0x221a
$BCEnabledDest  = "$($SourceFilePath)\Enabled"
$BCDisabledDest = "$($SourceFilePath)\Disabled"
$fileListSource = "$($SourceFilePath)\FileList"
$ExportFile     = "$($SourceFilePath)\Results_$(Get-Date -Format yyyyhhMM_HHmmss).CSV"

New-Item -Path $BCEnabledDest -ItemType Directory -Force | Out-Null
New-Item -Path $BCDisabledDest -ItemType Directory -Force | Out-Null
New-Item -Path $fileListSource -ItemType Directory -Force | Out-Null

function DownloadFiles {
    param (
        $fileObj,
        $Dest
    )
    Write-Host "--$($fileObj.FileName)" -ForegroundColor Cyan -NoNewline
    try {
        $filePath = Join-Path -Path $Dest -ChildPath $fileObj.FileName
        if ($fileObj.URL -like "HTTPS://*") {
            $BitsOptions = @{
                Source         = $fileObj.URL 
                Destination    = $filePath
                Credential     = $creds 
                Authentication = "NTLM"
            }
        }
        else {
            $BitsOptions = @{
                Source      = $fileObj.URL 
                Destination = $filePath
            }
        }

        $DLSeconds = Measure-Command { Start-BitsTransfer @BitsOptions } | Select-Object -ExpandProperty TotalSeconds

        if (Test-Path -Path $filePath) {
            $Hash = Get-FileHash -Path $filePath | Select-Object -ExpandProperty Hash
        }
        Write-Host $tick -ForegroundColor Green
        return $DLSeconds, $Hash
    }
    catch {
        return $_
    }
}

if (Test-Path "$($fileListSource)\*.csv") {
    $fileList = Get-ChildItem -Path $fileListSource | Get-Content | ConvertFrom-CSV | Select-Object -Unique URL
    Write-Host "Begin Processing $($fileList.Count) Files" -ForegroundColor Cyan
    
    #Enable BC
    Write-Host "-Enabling Branchcache on the client in Distributed Mode." -ForegroundColor Cyan
    Enable-BCDistributed | Out-Null
    Write-Host "-Clearing Branchcache cache on the client." -ForegroundColor Cyan
    Clear-BCCache -Force | Out-Null

    $fileObjs = @{}

    foreach ($file in $fileList) {
        if ($file.URL -like "*SMS_DP*") {
            $URL = $file.URL.Replace("/SCCM?", "").Replace("SMS_DP_SMSPKG", "NOCERT_SMS_DP_SMSPKG")
            $fileParts = $URL.Split("/")
            $fileName = $fileParts[$fileParts.count - 1]
        }
        else {
            $URL = $file.URL
            [regex]$regex = '(\/)(?!.*\/)(?<filename>.+)(\?)'
            if ($URL -match $regex) {
                $fileName = $matches.filename
            }
            else {
                $fileParts = $URL.Split("/")
                $fileName = $fileParts[$fileParts.count - 1]
            }
        }

        $fileObjs[$fileName] = [PSCustomObject]@{
            FileName       = $fileName
            URL            = $URL
            EnabledHash    = $null
            DisabledHash   = $null
            HashMatch      = $null
            EnabledDLTime  = $null
            DisabledDLTime = $null
            TimeDiff       = $null
        }
    }

    foreach ($Key in $fileObjs.Keys) {
        $fileObjs[$Key].EnabledDLTime, $fileObjs[$Key].EnabledHash = DownloadFiles -FileObj $fileObjs[$key] -Dest $BCEnabledDest
    }

    #Disable BC
    Write-Host "-Disabling Branch4cache on the client." -ForegroundColor Cyan
    Disable-BC -Force
    Write-Host "-Clearing Branchcache cache on the client." -ForegroundColor Cyan
    Clear-BCCache -Force
    
    foreach ($Key in $fileObjs.Keys) {
        $fileObjs[$Key].DisabledDLTime, $fileObjs[$Key].DisabledHash = DownloadFiles -FileObj $fileObjs[$key] -Dest $BCDisabledDest
        #FindMismatched hash values
        $fileObjs[$Key].HashMatch = $fileObjs[$Key].EnabledHash -match $fileObjs[$Key].DisabledHash
        #Find DL Time Difference 
        $fileObjs[$Key].TimeDiff = $fileObjs[$Key].DisabledDLTime - $fileObjs[$Key].EnabledDLTime
    }
 
    $fileObjs.values | Export-Csv -Path $ExportFile -Force

    #Re-Enable BranchCache
    Write-Host "-Re-Enabling Branchcache on the client in Distributed Mode." -ForegroundColor Cyan
    Enable-BCDistributed | Out-Null

}
else {
    Write-Host "No CSV Files Found. Run Get-BranchCacheError13FileList.ps1 on affected DP first." -ForegroundColor Yellow
}