

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


$creds = Get-Credential
$BCEnabledDest = "C:\BCTest\Enabled"
$BCDisabledDest = "C:\BCTest\Disabled"
$FileListSource = "C:\BCTest\FileList"

New-Item -Path $BCEnabledDest -ItemType Directory -Force
New-Item -Path $BCDisabledDest -ItemType Directory -Force
New-Item -Path $FileListSource -ItemType Directory -Force


if(Test-Path "$($FileListSource)\*.csv") {
$FileList = Get-ChildItem -Path $FileListSource | Get-Content | ConvertFrom-CSV
#Enable BC
Enable-BCDistributed
Clear-BCCache -Force

$FileObjs = @{}

ForEach($File in $FileList) {
    $FileParts = $File.URL.Split("/")
    $FileName = $FileParts[$FileParts.count-1]
    $URL = $File.URL.Replace("/SCCM?","").Replace("SMS_DP_SMSPKG","NOCERT_SMS_DP_SMSPKG")

    $FileObjs[$FileName] = [PSCustomObject]@{
        FileName = $FileName
        URL = $URL
        EnabledHash = $null
        DisabledHash = $null
    }
}

ForEach($Key in $FileObjs.Keys) {
    Start-BitsTransfer -Source $FileObjs[$key].URL -Destination $BCEnabledDest -Credential $creds -Authentication NTLM
    $FilePath = Join-Path -Path $BCEnabledDest -ChildPath $FileObjs[$key].FileName
    if(Test-Path -Path $FilePath) {
        $FileObjs[$Key].EnabledHash = Get-FileHash -Path $FilePath | Select-Object -ExpandProperty Hash
    }
}

#Disable BC
Disable-BC -Force
Clear-BCCache -Force

ForEach($Key in $FileObjs.Keys) {
    Start-BitsTransfer -Source $FileObjs[$key].URL -Destination $BCDisabledDest -Credential $creds -Authentication NTLM
    $FilePath = Join-Path -Path $BCDisabledDest -ChildPath $FileObjs[$key].FileName
    if(Test-Path -Path $FilePath) {
        $FileObjs[$Key].DisabledHash = Get-FileHash -Path $FilePath | Select-Object -ExpandProperty Hash
    }
}

    $FileObjs.values | Select-Object FileName,EnabledHash,DisabledHash
    #TODO - Add a comparison function to find all entries where hashes don't match each other to make it easier to find impacted files
}
else {
    Write-Host "No CSV Files Found. Run Get-BranchCacheError13FileList.ps1 on affected DP first."
}