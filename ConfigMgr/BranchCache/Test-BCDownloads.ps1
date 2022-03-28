<#
.SYNOPSIS
    tests BITS downloads to fins errors with BranchCache Content.

  Version:          1.3
  Author:           Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:    03/27/2022

  1.3 - Added Cert Auth by default
    
# Relies on script stolen from Johan Arwidmark
# https://github.com/DeploymentResearch/DRFiles/tree/master/Scripts/BranchCache
# Run Get-BranchCacheError13FileList.ps1
# Save Output to C:\BCTest\FileList (ore than one CSV file can be saved here)
# NOTE - If the impacted content is coming from MCC, this script doesn't work and I haven't sorted out why yet.

#>
[cmdletbinding()]
param(
    [string]$SourceFilePath = "C:\BCTest",
    [switch]$UseCredAuth = $True
)

$script:tick    = " " + [char]0x221a
$BCEnabledDest  = "$($SourceFilePath)\Enabled"
$BCDisabledDest = "$($SourceFilePath)\Disabled"
$fileListSource = "$($SourceFilePath)\FileList"
$ExportFile     = "$($SourceFilePath)\Results_$(Get-Date -Format yyyyhhMM_HHmmss).CSV"

New-Item -Path $BCEnabledDest -ItemType Directory -Force | Out-Null
New-Item -Path $BCDisabledDest -ItemType Directory -Force | Out-Null
New-Item -Path $fileListSource -ItemType Directory -Force | Out-Null

#Get Client Auth Cert
if($UseCredAuth.IsPresent) {
    $script:creds = Get-Credential
}
else {
    $Certs = Get-ChildItem -Path Cert:\CurrentUser\My
    $Cert = $Certs | Where-Object {$_.EnhancedKeyUsageList.FriendlyName -eq "Client Authentication" -and $_.Subject -like "*$($env:username)*"} | Select-Object -First 1 *
    $CertHash = for($i = 0; $i -lt $cert.Thumbprint.Length; $i += 2) {
        [convert]::ToByte($cert.Thumbprint.SubString($i, 2), 16)
    }
}

function DownloadFiles {
    param (
        $fileObj,
        $Dest
    )
    Write-Host "--$($fileObj.FileName)" -ForegroundColor Cyan -NoNewline
    try {
        $filePath = Join-Path -Path $Dest -ChildPath $fileObj.FileName
        if ($fileObj.URL -like "HTTPS://*") {
            if($CertHash) {
                $BitsOptions = @{
                    Source         = $fileObj.URL 
                    Destination    = $filePath
                    CertStoreLocation = "CurrentUser"
                    CertStoreName = "MY"
                    CertHash = $CertHash
                }
            }
            else {
                if(-not $script:Creds) {
                    $script:Creds = (Get-Credential)
                }
                $BitsOptions = @{
                    Source         = $fileObj.URL.Replace("SMS_DP_SMSPKG", "NOCERT_SMS_DP_SMSPKG")
                    Destination    = $filePath
                    Credential     = $script:Creds
                    Authentication = "NTLM"
                }
            }
        }
        else {
            $BitsOptions = @{
                Source      = $fileObj.URL 
                Destination = $filePath
            }
        }

        $DLSeconds = Measure-Command { Start-BitsTransfer @BitsOptions -ErrorAction Stop} | Select-Object -ExpandProperty TotalSeconds

        if (Test-Path -Path $filePath) {
            $Hash = Get-FileHash -Path $filePath | Select-Object -ExpandProperty Hash
        }
        Write-Host $tick -ForegroundColor Green
        return $DLSeconds, $Hash
    }
    catch {
        Write-Host X -ForegroundColor Red
        Write-Error $_
        return $Null, $Null
    }
}

if (Test-Path "$($fileListSource)\*.csv") {
    $fileList = Get-ChildItem -Path $fileListSource | Get-Content -raw | ConvertFrom-CSV | Select-Object -Unique URL
    Write-Host "Begin Processing $($fileList.Count) Files" -ForegroundColor Cyan
    
    #Enable BC
    Write-Host "-Enabling Branchcache on the client in Distributed Mode." -ForegroundColor Cyan
    Enable-BCDistributed | Out-Null
    Write-Host "-Clearing Branchcache cache on the client." -ForegroundColor Cyan
    Clear-BCCache -Force | Out-Null

    $fileObjs = @{}

    foreach ($file in $fileList) {
        if ($file.URL -like "*SMS_DP*") {
            $URL = $file.URL.Replace("/SCCM?", "")
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