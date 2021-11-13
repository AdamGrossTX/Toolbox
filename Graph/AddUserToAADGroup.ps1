$tenantID
$ApplicationClientID
$ClientSecret
$AccessToken

$UserName = "adsteven@intune.training"
$Group = "TESTGroup"
$Action = "Add"

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

    if(-not $AccessToken) {
        $AccessToken = Get-AccessToken -TenantID $tenantID -ApplicationClientID $ApplicationClientID -ClientSecret $ClientSecret
    }

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

    $DeleteParams = @{
        Headers = @{
            "Authorization" = "Bearer $($AccessToken)"
        }
        Method = "Delete"
        ErrorAction = "SilentlyContinue"
    }

    [string]$graphUrl = "https://graph.microsoft.com/beta"
    [string]$DevicesURL  = "$($GraphURL)/devices"
    [string]$UsersURL  = "$($GraphURL)/users"
    [string]$GroupsURL  = "$($GraphURL)/groups"

    $UserFilter = "/$($UserName)"
    $ManagedDevicesFilter = "/$($UserName)/managedDevices"
    $GroupFilter  = "?`$filter=displayName eq `'$($Group)`'"

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

    #Get Group
    try {
        $GetParams["URI"] = "$($GroupsURL)$($GroupFilter)"
        $GroupsResponse = Invoke-RestMethod @GetParams
        if($GroupsResponse.value){
            $Group = $GroupsResponse.value[0]
            Write-Host "Found Group: $($Group.displayName)"
        }
        else {
            Write-Host "No group found. Exiting."
            return
        }
    }
    catch {
        Write-Host "Error finding group."
    }

    try {
        $GetParams["URI"] = "$($GroupsURL)/{$($Group.Id)}/members/{$($User.Id)}"
        $GroupMember = Invoke-RestMethod @GetParams
    }
    catch {
        Write-Host "User not found in group."
        $GroupMember = $Null
    }

    [bool]$ActionCompleted = $false

    try {
        switch($Action) {
            "Add" {
                if($groupMember.Id -ne $user.Id) {
                    $PostParams["URI"] = "$($GroupsURL)/{$($Group.Id)}/members/`$ref"
                    $PostParams["ErrorAction"] = "Stop"
                    $PostParams["Body"] = (@{
                    "@odata.id" = "$($graphUrl)/directoryObjects/{$($User.Id)}"
                    } | ConvertTo-Json)
                    Invoke-RestMethod @PostParams
                    Write-Host "Added User: $($User.displayName)"
                    $ActionCompleted = $true
                }
                else {
                    Write-Host "User is already a member of the group. Skipping."
                }
            }
            "Remove" {
                if($groupMember.Id -eq $user.Id) {
                    $DeleteParams["URI"] = "$($GroupsURL)/{$($Group.id)}/members/{$($User.Id)}/`$ref"
                    $PostParams["ErrorAction"] = "Stop"
                    Invoke-RestMethod @DeleteParams
                    Write-Host "Removed User: $($User.displayName)"
                    $ActionCompleted = $true
                }
                else {
                    Write-Host "User isn't in the group. Skipping."
                }
            }
        }
    }
    catch {

    }


    if($ActionCompleted) {
        #Pause for 2 mins to allow the group to update
        Start-Sleep -Seconds 120

        try {
            $GetParams["URI"] = "$($UsersURL)$($ManagedDevicesFilter)"
            $ManagedDevicesResponse = Invoke-RestMethod @GetParams
            if ($ManagedDevicesResponse.value) {
                foreach ($ManagedDevice in $ManagedDevicesResponse.value) {
                    $PostParams.Remove("Body")
                    $PostParams.Remove("URI")
                    $PostParams["URI"] = "$($graphUrl)/deviceManagement/managedDevices/{$($ManagedDevice.Id)}/syncDevice"
                    $Response = Invoke-WebRequest @PostParams
                    if ($Response.StatusCode -eq 204) {
                        Write-Host "Synced $($ManagedDevice.deviceName)"
                    }
                    else {
                        Write-Host "Failed to Sync $($ManagedDevice.deviceName)"
                        Write-Host "$($Response).StatusCode"
                    }
                }
            }
        }
        catch {

        }
<#
        try {
            $PolicyKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Policy Manager"
            $InitialValue = Get-ItemPropertyValue -Path registry::$PolicyKey -Name "PolicyRules" -ErrorAction SilentlyContinue
            Do {
                $Count++
                $NewValue = Get-ItemPropertyValue -Path registry::$PolicyKey -Name "PolicyRules" -ErrorAction SilentlyContinue
                start-sleep -Seconds 1
            } until ($InitialValue -ne $NewValue)
            $Count
        }
        catch {

        }
        #>
    }
