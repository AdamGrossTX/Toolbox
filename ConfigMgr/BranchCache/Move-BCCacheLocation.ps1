<#
.SYNOPSIS
    Moves BranchCache location for ConfigMgr DPs

  Version:          1.0
  Author:           Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:    03/27/2022
    
#>

$NewHashFolder = "E:\BCPublicationCache"
$NewHashSize = 10
$BCStatus = Get-BCStatus
$BCStatus
if($NewHashFolder -ne $BCStatus.HashCache.CacheFileDirectoryPath) {
    Get-Service PeerDistSvc | stop-service
    Clear-BCCache -Force
    New-Item -Path $NewHashFolder -ItemType Directory -force

    Set-BCCache -Path $BCStatus.HashCache.CacheFileDirectoryPath -MoveTo $NewHashFolder -Force
    $BCHashCache = Get-BCHashCache
    $BCHashCache | Set-BCCache -Percentage $NewHashSize -Force
    Start-Service PeerDistSvc
}
$BCStatus = Get-BCStatus; $BCStatus.HashCache.CacheFileDirectoryPath; 