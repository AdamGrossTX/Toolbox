<#
.NOTES
    Author:           Adam Gross - @AdamGrossTX
    GitHub:           https://www.github.com/AdamGrossTX
    WebSite:          https://www.asquaredozen.com

#>
[cmdletbinding()]
param(
    [string]$UserUPN        = "adam@asquaredozenlab.com",
    #[string]$UserUPN        = "joe@asquaredozenlab.com",
    [string]$SMSProvider    = "cm01.asd.net",
    [string]$AdminServiceWebURI = "adminservice.asquaredozenlab.com"
)
$AdminServiceWebURI = if(-not $AdminServiceWebURI) {$SMSProvider} else {$AdminServiceWebURI}

#region Get Secrets from Local File for Demo
$Secrets = Get-Content .\secrets.json -Raw | ConvertFrom-Json
[SecureString]$SecurePassword = $Secrets.AdminService.Password | ConvertTo-SecureString -AsPlainText -Force
[PSCredential]$CredObject = New-Object System.Management.Automation.PSCredential -ArgumentList $Secrets.AdminService.UserName, $SecurePassword

#endregion

#region SiteCodes
$SiteCodes = @{
    "Houston" = "HOU"
    "Miami"   = "MIA"
    "Unknown" = "UNK"
}
#endregion

#region Graph URLs
[string]$GraphUrl               = "https://graph.microsoft.com/beta"
[string]$AADUsersUrl            = "$($GraphUrl)/users"
[string]$AADUserFilter          = "/$($UserUPN)"
[string]$DeviceManagementUrl    = "$($GraphUrl)/deviceManagement/managedDevices"
[string]$ManagedDevicesFilter   = "/$($UserUPN)/managedDevices"
#[string]$AADDevicesUrl = "$($GraphUrl)/devices"
#[string]$AutopilotDevicesUrl = "$($GraphUrl)/deviceManagement/windowsAutopilotDeviceIdentities"
#endregion

#region AdminService URLs
[string]$VersionedBaseUrl       = "https://$($AdminServiceWebURI)/AdminService/v1.0"
[string]$WMIBaseUrl             = "https://$($AdminServiceWebURI)/AdminService/wmi"
[string]$DeviceClassURL         = "$($VersionedBaseUrl)/Device"
[string]$WMIDeviceClassURL      = "$($WMIBaseUrl)/SMS_R_System"
[string]$WMIUserClassURL        = "$($WMIBaseUrl)/SMS_R_User"
[string]$WMIUserMachRelURL      = "$($WMIBaseUrl)/SMS_UserMachineRelationship.CreateRelationship"
#endregion

#region functions
function Get-AccessToken {
    [cmdletbinding()]
    param(
        [string]$TenantID,
        [string]$ApplicationClientID,
        [string]$ClientSecret
    )

    try {

        [string]$graphUrl = "https://graph.microsoft.com"
        [string]$tokenEndpoint = "https://login.microsoftonline.com/$($tenantID)/oauth2/token"
        
        $PostParams = @{
            Headers = @{
                "Content-Type" = "application/x-www-form-urlencoded"
            }
            Body = @{
                grant_type    = "client_credentials"
                client_id     = $ApplicationClientID
                client_secret = $ClientSecret
                resource      = $graphUrl
            }
            Method      = "POST"
            URI         = $tokenEndpoint
            ErrorAction = "SilentlyContinue"
        }
        # Post request to get the access token so we can query the Microsoft Graph (valid for 1 hour)
        $response = Invoke-RestMethod @PostParams
        return $response.access_token
    }
    catch {
        throw $_
    }
}
function Get-SerialNumber {
    param(
        [string]$Manufacturer,
        [string]$SerialNumber,
        [string]$Model
    )
    try {
        $SerialNumber = $SerialNumber.Replace("-", "")
        If ($Manufacturer -like "*Microsoft*") {
            #trim the trailing 4 chars since they are the same across most models. Per Microsoft...
            $CharsToTrim = $SerialNumber.Length - 8
            $SerialNumber = $SerialNumber.Substring(0, $SerialNumber.Length - $CharsToTrim)
        }
        ElseIf ($SerialNumber.Length -gt 8) {
            $CharsToTrim = $SerialNumber.Length - 8
            $SerialNumber = $SerialNumber.remove(0, $CharsToTrim)
        }
        Return $SerialNumber
    }
    catch {
        throw $_
    }
}
function Connect-CMSite {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory=$False)]
        [string]$Script:SiteServer,

        [Parameter(Mandatory=$False)]
        [string]$Script:SiteCode
    )

    try {

        if (-not $Script:SiteServer) {
            $Script:SiteServer = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\CCM\FSP" -Name "HostName" -ErrorAction Stop
        }
        if (-not $Script:SiteCode) {
            $Script:SiteCode = Get-CimInstance -Namespace "root\SMS" -ClassName "SMS_ProviderLocation" -ComputerName $SiteServer -ErrorAction Stop | Select-Object -ExpandProperty SiteCode
        }

        Write-Host " + Connecting to ConfigMgr Site $($Script:SiteServer) - $($Script:SiteCode)" -ForegroundColor Cyan -NoNewline
        if ((Get-Module ConfigurationManager) -eq $null) {
            Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
        }
    
        if ((Get-PSDrive -Name $Script:SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
            New-PSDrive -Name $Script:SiteCode -PSProvider CMSite -Root $Script:SiteServer
        }
        Set-Location "$($Script:SiteCode):\"

        Write-Host $Script:tick -ForegroundColor green
    }
    catch {
        throw $_
    }
}
#endregion

#region default params
$TokenParams = @{
    TenantID            = $Secrets.Graph.TenantID
    ApplicationClientID = $Secrets.Graph.AppID
    ClientSecret        = $Secrets.Graph.Secret
}
$AccessToken = Get-AccessToken @TokenParams
#graph
$graphGetParams = @{
    Headers     = @{
        "Content-Type"  = "application/json"
        "Authorization" = "Bearer $($AccessToken)"
    }
    Method      = "GET"
    ErrorAction = "SilentlyContinue"
}

$graphPostParams = @{
    Headers     = @{
        "Authorization" = "Bearer $($AccessToken)"
        "Accept"        = "application/json"
        "Content-Type"  = "application/json"
    }
    Method      = "POST"
    ErrorAction = "SilentlyContinue"
}

$graphPatchParams = @{
    Headers     = @{
        "Authorization" = "Bearer $($AccessToken)"
        "Content-Type"  = "application/json"
    }
    Method      = "PATCH"
    ErrorAction = "SilentlyContinue"
}

#AdminService
$asGetParams = @{
    Method                = "GET"
    ContentType           = "application/json"
    ErrorAction           = "SilentlyContinue"
}

if($AdminServiceWebURI -ne $SMSProvider) {
    $asGetParams["Credential"] = $CredObject
}
else {
    $asGetParams["UseDefaultCredential"] = $True
}

$asPostParams = @{
    Method                = "POST"
    ContentType           = "application/json"
    ErrorAction           = "SilentlyContinue"
}

if($AdminServiceWebURI -ne $SMSProvider) {
    $asPostParams["Credential"] = $CredObject
}
else {
    $asPostParams["UseDefaultCredentials"] = $True
}

#endregion

#######
#GRAPH#
#######

    #region Get AAD User

    try {
        $graphGetParams["URI"] = "$($AADUsersUrl)$($AADUserFilter)"
        $AADUser = Invoke-RestMethod @graphGetParams
        if ($AADUser) {
            Write-Host "Found User: $($AADUser.displayName)"
        }
        else {
            Write-Host "No user found. Exiting."
            return
        }
    }
    catch {
        Write-Host "Error Finding user."
    }
    #endregion
    #region Get Intune Managed Device
    try {
        $graphGetParams["URI"] = "$($AADUsersUrl)$($ManagedDevicesFilter)"
        $ManagedDevicesResponse = Invoke-RestMethod @graphGetParams
        $ManagedDevices = $ManagedDevicesResponse.value
    }
    catch {
        Write-Error "Error finding managed devices for user:$AADUser.DisplayName"
    }

    foreach ($ManagedDevice in $ManagedDevices) {
        try {
            $Prefix = if($AADUser.city) {
                $SiteCodes[$AADUser.city]
            }
            else {
                $SiteCodes["Unknown"]
            }

            $Serial = Get-SerialNumber -SerialNumber $ManagedDevice.serialNumber -Manufacturer $ManagedDevice.manufacturer -Model $ManagedDevice.Model
            if ($Serial -and $Prefix) {
                $managedDeviceName = "$($Prefix)-$($Serial)"
                if ($ManagedDevice.managedDeviceName -ne $managedDeviceName) {
                    $graphPatchParams.Body = @{"managedDeviceName" = $managedDeviceName } | ConvertTo-Json
                    $graphPatchParams["URI"] = "$($DeviceManagementUrl)/$($ManagedDevice.Id)"
                    $PatchResponse = Invoke-WebRequest @graphPatchParams
                    if ($PatchResponse.StatusCode -eq 204) {
                        Write-Host "Updated $($ManagedDevice.deviceName)"
                    }
                    else {
                        Write-Host "Failed to update $($ManagedDevice.deviceName)"
                        Write-Host "$($PatchResponse).StatusCode"
                    }
                }
            }
        }
        catch {
            throw $_
        }
    }
    #endregion


    ##############
    #AdminService#
    ##############

    #region Get ConfigMgr User
    try {
        $asGetParams["URI"] = "$($WMIUserClassURL)?`$filter=AADUserID eq `'$($AADUser.ID)`'"
        $UserResponse = Invoke-RestMethod @asGetParams
        if ($UserResponse.value) {
            $ADUser = $UserResponse.value
        }
        else {
            return
        }
    }
    catch {
        Write-Output "No AD User Found for user: $($AADUser.userPrincipalName)"
    }

    foreach ($ManagedDevice in $ManagedDevices) {
        try {
            $asGetParams["URI"] = "$($WMIDeviceClassURL)?`$filter=AADDeviceID eq `'$($ManagedDevice.azureActiveDirectoryDeviceId)`'"
            $CMDeviceResponse = Invoke-RestMethod @asGetParams
            if ($CMDeviceResponse.value) {
                $CMDevice = $CMDeviceResponse.value
                Write-Output "Found ConfigMgr Device: $($CMDevice.Name)"
            }
        }
        catch {
            Write-Output "No CM Device found for device: $($ManagedDevice.deviceName)"
        }

        if ($CMDevice) {
            try {
                $DeviceObj = [PSCustomObject]@{
                    ResourceId    = $CMDevice.ResourceId
                    DeviceName    = $CMDevice.Name
                    UserId        = $ADUser.ResourceID
                    UserName      = $ADUser.UserPrincipalName
                    ExtensionData = $null
                }

                $asGetParams["URI"] = "$($DeviceClassURL)($($CMDevice.ResourceId))/AdminService.GetExtensionData"
                $ExtensionDataResponse = Invoke-RestMethod @asGetParams
                if ($ExtensionDataResponse."@odata.context") {
                    $ExtensionDataResponse.psobject.properties.Remove("@odata.context")
                    $ExtensionDataResponse.psobject.properties.Remove("ExtendedType")
                    $ExtensionDataResponse.psobject.properties.Remove("InstanceKey")
                }
                $ExtensionData = $ExtensionDataResponse

                if ($ExtensionData) {
                    foreach ($property in $ExtensionData.psobject.Properties) {
                        $DeviceObj.psobject.Properties.Add($Property)
                    }
                }
                $DeviceObj.ExtensionData = $ExtensionData

                $DeviceObj
            }
            catch {
                $ExtensionDataResponse = $null
            }
        }
    #endregion

        #region SetExtensionData
        if ($CMDevice) {
            try {
                $asPostParams["Body"] = @{
                    ExtensionData = @{
                        Location          = $AADUser.City
                        ManagedDeviceName = $managedDeviceName
                        SiteCode          = $Prefix
                    }
                } | ConvertTo-Json
                $asPostParams["URI"] = "$($DeviceClassURL)($($CMDevice.ResourceId))/AdminService.SetExtensionData"
                $SetExtensionDataResponse = Invoke-RestMethod @asPostParams
            }
            catch {
                
            }
        }
        #endregion

        #region Set UserMachRel
        
        if ($CMDevice) {
            try {
                $asPostParams["Body"] = @{
                    MachineResourceId = $CMDevice.ResourceId
                    SourceId          = 6 #OSD Defined
                    TypeId            = 1
                    UserAccountName   = $ADUser.UniqueUserName
                } | ConvertTo-Json
                $asPostParams["URI"] = $WMIUserMachRelURL
                $SetUserMachRelResponse = Invoke-RestMethod @asPostParams
            }
        catch {

        }
        #endregion
    }
}

  #region Create ConfigMgr Location Collections  
    try {
        $asGetParams["URI"] = "$($DeviceClassURL)/AdminService.GetExtensionData"
        $CMDeviceExtensionDataResponse = Invoke-RestMethod @asGetParams
        if ($CMDeviceExtensionDataResponse.value) {
            $CMDeviceExtensionData = $CMDeviceExtensionDataResponse.value
        }
    }
    catch {
        Write-Output "No CM Device found for device: $($ManagedDevice.deviceName)"
    }

if($AdminServiceWebURI -eq $SMSProvider) {
    try {
        $LocationData = $CMDeviceExtensionData | Select-Object Location, SiteCode  -Unique

        Connect-CMSite

        Write-Output "Creating ConfigMgr Collections"
        foreach($Location in $LocationData) {
            $ExistingCollection = Get-CMCollection -Name $Location.Location -ErrorAction SilentlyContinue
            if(-not $ExistingCollection) {

                $NewCollectionSplat         = @{
                    LimitingCollectionId    = "SMS00001"
                    Name                    = $Location.Location
                    RefreshType             = "Continuous"
                }

                $Collection = New-CMDeviceCollection @NewCollectionSplat
                if($Collection) {
                    $NewQueryRuleSplat  = @{
                        RuleName        = $Location.Location
                        CollectionId    = $Collection.CollectionID
                        QueryExpression = "select *  from  SMS_R_System inner join SMS_G_System_ExtensionData on SMS_G_System_ExtensionData.ResourceId = SMS_R_System.ResourceId where SMS_G_System_ExtensionData.PropertyName = `"SiteCode`" and SMS_G_System_ExtensionData.PropertyValue = `"$($Location.SiteCode)`""
                    }

                    Add-CMDeviceCollectionQueryMembershipRule @NewQueryRuleSplat
                    Write-Output "Created new ConfigMgr collection: $($Location.Location)"
                }
            }
        }

        Set-location c:
    }
    catch {
        throw $_
    }
}
#endregion


<#
try {
    $asPostParams["Body"] = $Null
    $asPostParams["URI"] = "$($DeviceClassURL)/AdminService.DeleteExtensionData"
    $DeleteExtensionDataResponse = Invoke-RestMethod @asPostParams
}
catch {
    "No Extension Data to Delete"
}#>
