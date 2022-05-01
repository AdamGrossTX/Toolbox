<#
.NOTES
    Author:           Adam Gross - @AdamGrossTX
    GitHub:           https://www.github.com/AdamGrossTX
    WebSite:          https://www.asquaredozen.com

#>
[cmdletbinding()]
param(
    [string]$UserUPN
)

<# #Region use Azure RunAs Connection in Runbook. Uncomment this block for runbook, comment out Connect-AzAccount below
$connectionName = "AzureRunAsConnection"

$ServicePrincipalConnection = Get-AutomationConnection -name $connectionName

$connect = Connect-AzAccount -ServicePrincipal `
    -TenantId $servicePrincipalConnection.TenantId `
    -ApplicationId $servicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
#End Region
 #>

#Region Connect to Azure to get client secret
Connect-AzAccount

$ConnectionSecrets = Get-AzKeyVaultSecret -VaultName "MME-AKV" -Name "MMSDemo" -AsPlainText
$tenantID = $ConnectionSecrets.Split()[0]
$ApplicationClientID = $ConnectionSecrets.Split()[2]
$ClientSecret = $ConnectionSecrets.Split()[4]

$TokenParams = @{
    TenantID = $tenantID
    ApplicationClientID = $ApplicationClientID
    ClientSecret = $ClientSecret
}
#End Region


#region Params
[string]$GraphUrl = "https://graph.microsoft.com/beta"
[string]$DevicesURL  = "$($GraphUrl)/devices"
[string]$UsersURL  = "$($GraphUrl)/users"

$UserFilter = "/$($UserUPN)"
$ManagedDevicesFilter = "/$($UserUPN)/managedDevices"
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
        $tokenHeaders = @{
            "Content-Type" = "application/x-www-form-urlencoded"
        }

        $tokenBody = @{
            grant_type    = "client_credentials"
            client_id     = $ApplicationClientID
            client_secret = $ClientSecret
            resource      = $graphUrl
        }

        # Post request to get the access token so we can query the Microsoft Graph (valid for 1 hour)
        $response = Invoke-RestMethod -Method Post -Uri $tokenEndpoint -Headers $tokenHeaders -Body $tokenBody -ErrorAction SilentlyContinue
        return $response.access_token
    }
    catch {
        throw $_
    }
}
#endregion

$AccessToken = Get-AccessToken @TokenParams

$GetParams = @{
    Headers = @{
        "Content-Type"  = "application/json"
        "Authorization" = "Bearer $($AccessToken)"
    }
    Method = "Get"
    ErrorAction = "SilentlyContinue"
}


$PostParams = @{
    Headers = @{
        "Authorization" = "Bearer $($AccessToken)"
        "Accept" = "application/json"
        "Content-Type" = "application/json"
    }
    Method = "Post"
    ErrorAction = "SilentlyContinue"
}


#Get User
try {
    $GetParams["URI"] = "$($UsersURL)$($UserFilter)"
    $User = Invoke-RestMethod @GetParams
    if($User){
        Write-Host "Found User: $($User.displayName)"
    }
    else {
        Write-Host "No user found. Exiting."
        return
    }
}
catch {
    Write-Host "Error Finding user."
}

try {
    $GetParams["URI"] = "$($UsersURL)$($ManagedDevicesFilter)"
    $ManagedDevicesResponse = Invoke-RestMethod @GetParams
}
catch {
    Write-Error "Error finding managed devices for user:$User.DisplayName"
}

if ($ManagedDevicesResponse.value) {
    $Devices = [System.Collections.ArrayList]::new()
    foreach($device in $ManagedDevicesResponse.value) {
        #get each device's AAD Object
        try {
            $GetParams["URI"] = "$($devicesURL)/deviceId_$($device.azureActiveDirectoryDeviceId)"
            $AADDevice = Invoke-RestMethod @GetParams
            Write-Output "Device: $($Device.DeviceName)"
        }
        catch {
            Write-Output "No Azure AD Object found: $($device.DeviceName)"
        }

        if($AADDevice) {
            $physicalIdObj = @{}
            if($AADDevice.physicalIds) {
                foreach($physicalid in $AADDevice.physicalIds) {
                    $items = $physicalid.split(':',2)
                    if($items) {
                        $idName = $items[0].Replace('[','').Replace(']','')
                        $idValue = $items[1]
                        $physicalIdObj[$idName] = $idValue
                    }
                }
            }

            $deviceObj = [PSCustomObject]@{
                id = $AADDevice.id
                deviceName = $AADDevice.displayName
                groupTag = $physicalIdObj.OrderId
                physicalIds = $physicalIdObj
                managedBy = $device.managementAgent
            }

            [void]$Devices.Add($deviceObj)
        }
        else {
            Write-Output "Could not find device: $($device.DeviceName)"
        }
    }
}
    


        #https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities


    #    foreach ($ManagedDevice in $ManagedDevicesResponse.value) {
    #        $PostParams.Remove("Body")
    #        $PostParams.Remove("URI")
    #        $PostParams["URI"] = "$($graphUrl)/deviceManagement/managedDevices/{$($ManagedDevice.Id)}"
            #$Response = Invoke-WebRequest @PostParams
            #if ($Response.StatusCode -eq 204) {
            #    Write-Host "Synced $($ManagedDevice.deviceName)"
            #}
            #else {
            #    Write-Host "Failed to Sync $($ManagedDevice.deviceName)"
            #    Write-Host "$($Response).StatusCode"
            #}
    #    }

$Devices | ConvertTo-Json

#endregion