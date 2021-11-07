<DownloadStatsList><Host HostName="BRANCHCACHE"><DownloadType Type="0"><StartTime StartTime="1589000400"><Content BytesDownloaded="2301931043" ID="Content_863c31af-e6dc-4d04-a41a-05944120b5d8"/></StartTime></DownloadType></Host><Host HostName="CM01.ASD.NET"><DownloadType Type="0"><StartTime StartTime="1588914000"><Content BytesDownloaded="30930451" ID="Content_3520541a-a5e5-4350-9b04-fba19a44e50e"/></StartTime><StartTime StartTime="1589000400"><Content BytesDownloaded="62773721" ID="Content_863c31af-e6dc-4d04-a41a-05944120b5d8"/></StartTime></DownloadType></Host><ClientLocationInfo><BoundaryGroups BoundaryGroupListRetrieveTime="2020-05-09T18:28:49.580"><BoundaryGroup GroupID="16777218" GroupGUID="54f5241d-9169-4966-8591-42839c72c634" GroupFlag="4"/><DOINCServers><DOINCServer DOINCServer="CM01.ASD.NET"/></DOINCServers></BoundaryGroups></ClientLocationInfo></DownloadStatsList>

foreach($record in $d.DownloadStatsList.Host){
    [pscustomobject]@{
        DownloadHost = $record.HostName
        DownloadType = $record.DownloadType.Type
        DownloadStartTime = $record.DownloadType.StartTime.StartTime
        Content = foreach($ContentRecord in $record.DownloadType.StartTime.Content){
            [pscustomobject]@{
                ContentID = $ContentRecord.ID
                BytesDownloaded = $ContentRecord.BytesDownloaded    
                }
        }
        BoundaryGroupListRetrieveTime = $record.ClientLocationInfo.BoundaryGroups
    }
}

$NameSpace = 'root\ccm\StateMsg'
$ClassName = 'CCM_StateMsg'
$TopicID = "STATE_STATEID_DOWNLOAD_AGGREGATE_DATA_UPLOAD"
$TopicType = 7202


Get-CIMInstance -Namespace $NameSpace -Class $ClassName -Filter "TopicType = $($TopicType)"

[XML]$StateDetails = $StateMessageInstance.StateDetails

$HostList = $StateDetails.DownloadStatsList.Host

$Hosts = @()
ForEach ($DOHost in $HostList) {

    $HostObj = [PSCustomObject]@{}

    $HostObj | Add-Member -MemberType NoteProperty -Name "HostName" -Value $DOHost.HostName
    $HostObj | Add-Member -MemberType NoteProperty -Name "DownloadType" -Value $DOHost.DownloadType.Type
    $HostObj | Add-Member -MemberType NoteProperty -Name "StartTime" -Value $DOHost.DownloadType.StartTime.StartTime

    ForEach ($Content in $DOHost.DownloadType.StartTime.StartTime.Content) {
        $ContentObj = [PSCustomObject]@{}
        $ContentObj | Add-Member -MemberType NoteProperty -Name "BytesDownloaded" -Value $Content.BytesDownloaded
        $ContentObj | Add-Member -MemberType NoteProperty -Name "ID" -Value $Content.ID
        $HostObj | Add-Member -MemberType NoteProperty -Name "Content" -Value $ContentObj
    }
    $Hosts += $HostObj
}

$Hosts.Content

$ClientLocationInfo = $StateDetails.DownloadStatsList.ClientLocationInfo

$Locations = @()
ForEach ($Location in $ClientLocationInfo) {
    $LocationObj = [PSCustomObject]@{}

    $LocationObj | Add-Member -MemberType NoteProperty -Name "BoundaryGroupListRetrieveTime" -Value $BoundaryGroups.BoundaryGroupListRetrieveTime

    $BoundaryGroups = $Location.BoundaryGroups
    $BoundaryGroupListRetrieveTime = $BoundaryGroups.BoundaryGroupListRetrieveTime
    $BoundaryGroupListRetrieveTime
    ForEach ($BoundaryGroup in $BoundaryGroups) {
        $GroupID = $BoundaryGroup.GroupID
        $GroupGUID = $BoundaryGroup.GroupGUID
        $GroupFlag = $BoundaryGroup.GroupFlag
        
        $GroupID
        $GroupGUID
        $GroupFlag
    }
}


$DODownloadModes = @{
    0 = "HTTP Only"
    1 = "LAN"
    2 = "Group"
    3 = "Internet"
    99 = "Simple"
    100 = "Bypass"
}

$DOGroupIDSources = @{
    0 = "not set"
    1 = "AD Site"
    2 = "Authenticated domain SID"
    3 = "DHCP Option ID"
    4 = "DNS Suffix"
    5 = "Azure Active Directory (AAD) Tenant ID"
}

$DOPolicies = Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization | Select-Object * -Exclude PSPath, PSParentPath, PSChildName, PSProvider, PSDrive

#https://docs.microsoft.com/en-us/windows/deployment/update/waas-delivery-optimization-reference

$DOPolicies | Get-Member -MemberType NoteProperty | ForEach-Object {$_.Name} | ForEach-Object {
    $Value = Switch -case ($_) {
        "DODownloadMode" {
            "$($DOPolicies.$_) ($($DODownloadModes[$DOPolicies.$_]))";
            break;
        }
        "DOGroupIDSource" {
            $DOGroupIDSources[$DOPolicies.$_];
            break;
        }
        Default {
            $DOPolicies.$_;
            break;
        }
    }
    $_ + '=' + $Value
}

<#

"DODownloadMode" = "download-mode"
"DOGroupID" = "group-id"
"DOMinRAMAllowedToPeer" = "minimum-ram-inclusive-allowed-to-use-peer-caching"
"DOMinDiskSizeAllowedToPeer" = "minimum-disk-size-allowed-to-use-peer-caching"
"DOMaxCacheAge" = "max-cache-age"
"DOMaxCacheSize" = "max-cache-size"
"DOAbsoluteMaxCacheSize" = "absolute-max-cache-size"
"DOModifyCacheDrive" = "modify-cache-drive"
"DOMinFileSizeToCache" = "minimum-peer-caching-content-file-size"
"DOMaxDownloadBandwidth" = "maximum-download-bandwidth"
"DOPercentageMaxDownloadBandwidth" = "percentage-of-maximum-download-bandwidth"
"DOMaxUploadBandwidth" = "max-upload-bandwidth"
"DOMonthlyUploadDataCap" = "monthly-upload-data-cap"
"DOMinBackgroundQoS" = "minimum-background-qos"
"DOAllowVPNPeerCaching" = "enable-peer-caching-while-the-device-connects-via-vpn"
"DOMinBatteryPercentageAllowedToUpload" = "allow-uploads-while-the-device-is-on-battery-while-under-set-battery-level"
"DOPercentageMaxForegroundBandwidth" = "maximum-foreground-download-bandwidth"
"DOPercentageMaxBackgroundBandwidth" = "maximum-background-download-bandwidth"
"DOSetHoursToLimitBackgroundDownloadBandwidth" = "set-business-hours-to-limit-background-download-bandwidth"
"DOSetHoursToLimitForegroundDownloadBandwidth" = "set-business-hours-to-limit-foreground-download-bandwidth"
"DORestrictPeerSelectionBy" = "select-a-method-to-restrict-peer-selection"
"DOGroupIDSource" = "select-the-source-of-group-ids"
"DODelayBackgroundDownloadFromHttp" = "delay-background-download-from-http-in-secs"
"DODelayForegroundDownloadFromHttp" = "delay-foreground-download-from-http-in-secs"
"DelayCacheServerFallbackForeground" = "delay-foreground-download-cache-server-fallback-in-secs"
"DelayCacheServerFallbackBackground" = "delay-background-download-cache-server-fallback-in-secs"
#>

[9:58 PM, 5/16/2020] Ben Reader: function ConvertFrom-Xml {
    <#
    .SYNOPSIS
        Converts XML object to PSObject representation for further ConvertTo-Json transformation
    .EXAMPLE
        # JSON->XML
        $xml = ConvertTo-Xml (get-content 1.json | ConvertFrom-Json) -Depth 4 -NoTypeInformation -as String
    .EXAMPLE
        # XML->JSON
        ConvertFrom-Xml ([xml]($xml)).Objects.Object | ConvertTo-Json
    #>
    param(
        [System.Xml.XmlElement]$Object
    )
    
    if (($Object -ne $null) -and ($Object.Property -ne $null)) {
        $PSObject = New-Object PSObject
    
        foreach ($Property in @($Object.Property)) {
            if ($Property.Property.Name -like 'Property') {
                $PSObject | Add-Member NoteProperty $Property.Name ($Property.Property | % { ConvertFrom-Xml $_ })
            }
            else {
                if ($Property.'#text' -ne $null) {
                    $PSObject | Add-Member NoteProperty $Property.Name $Property.'#text'
                }
                else {
                    if ($Property.Name -ne $null) {
                        $PSObject | Add-Member NoteProperty $Property.Name (ConvertFrom-Xml $Property)
                    }
                }
            } 
        }   
        $PSObject
    }
}