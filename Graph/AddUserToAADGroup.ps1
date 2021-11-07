$tenantID = "f7b5c879-0a00-4aec-b5a2-4dde5ba79aa4"
$ApplicationClientID
$ClientSecret
$AccessToken = "eyJ0eXAiOiJKV1QiLCJub25jZSI6IllMbTFaOFBycHdOZ3JkWmU0eXRmQ2ZELXhISU15Rktrbk9TRUNtNi1meEkiLCJhbGciOiJSUzI1NiIsIng1dCI6Imwzc1EtNTBjQ0g0eEJWWkxIVEd3blNSNzY4MCIsImtpZCI6Imwzc1EtNTBjQ0g0eEJWWkxIVEd3blNSNzY4MCJ9.eyJhdWQiOiIwMDAwMDAwMy0wMDAwLTAwMDAtYzAwMC0wMDAwMDAwMDAwMDAiLCJpc3MiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC9mN2I1Yzg3OS0wYTAwLTRhZWMtYjVhMi00ZGRlNWJhNzlhYTQvIiwiaWF0IjoxNjMxOTM2NDQ2LCJuYmYiOjE2MzE5MzY0NDYsImV4cCI6MTYzMTk0MDM0NiwiYWNjdCI6MCwiYWNyIjoiMSIsImFpbyI6IkFVUUF1LzhUQUFBQUxTbWs1ZjAvekpoQzFyM2QxOUhsYnZTdjcwS2tXcm5DN1RFYkZydWMyZWdRcXdyVW5aUC9RSithL0FWZGRqcFlvNmErcHpDZWlkdFppeUJBYlhwVXlBPT0iLCJhbXIiOlsicHdkIiwicnNhIiwibWZhIl0sImFwcF9kaXNwbGF5bmFtZSI6IkdyYXBoIEV4cGxvcmVyIiwiYXBwaWQiOiJkZThiYzhiNS1kOWY5LTQ4YjEtYThhZC1iNzQ4ZGE3MjUwNjQiLCJhcHBpZGFjciI6IjAiLCJkZXZpY2VpZCI6ImMwZjZkMDJjLTc0ZDYtNDhkNi04MjNmLWMxYzQxNWVmMWY0MSIsImZhbWlseV9uYW1lIjoiR3Jvc3MiLCJnaXZlbl9uYW1lIjoiQWRhbSIsImlkdHlwIjoidXNlciIsImlwYWRkciI6IjEzNi4yNDQuNDIuNjkiLCJuYW1lIjoiQWRhbSBHcm9zcyIsIm9pZCI6ImJlZTUyMTQwLTlmMTEtNDk0My05Nzg2LWMzNzQyYTA3MTg5NCIsInBsYXRmIjoiMyIsInB1aWQiOiIxMDAzMjAwMDRCRDI3RTQwIiwicmgiOiIwLkFVRUFlY2kxOXdBSzdFcTFvazNlVzZlYXBMWElpOTc1MmJGSXFLMjNTTnB5VUdSQkFOay4iLCJzY3AiOiJDYWxlbmRhcnMuUmVhZFdyaXRlIENvbnRhY3RzLlJlYWRXcml0ZSBEZXZpY2VNYW5hZ2VtZW50QXBwcy5SZWFkLkFsbCBEZXZpY2VNYW5hZ2VtZW50QXBwcy5SZWFkV3JpdGUuQWxsIERldmljZU1hbmFnZW1lbnRDb25maWd1cmF0aW9uLlJlYWQuQWxsIERldmljZU1hbmFnZW1lbnRDb25maWd1cmF0aW9uLlJlYWRXcml0ZS5BbGwgRGV2aWNlTWFuYWdlbWVudE1hbmFnZWREZXZpY2VzLlJlYWRXcml0ZS5BbGwgRGV2aWNlTWFuYWdlbWVudFNlcnZpY2VDb25maWcuUmVhZC5BbGwgRGV2aWNlTWFuYWdlbWVudFNlcnZpY2VDb25maWcuUmVhZFdyaXRlLkFsbCBEaXJlY3RvcnkuQWNjZXNzQXNVc2VyLkFsbCBEaXJlY3RvcnkuUmVhZC5BbGwgRGlyZWN0b3J5LlJlYWRXcml0ZS5BbGwgRmlsZXMuUmVhZFdyaXRlLkFsbCBNYWlsLlJlYWRXcml0ZSBOb3Rlcy5SZWFkV3JpdGUuQWxsIG9wZW5pZCBQZW9wbGUuUmVhZCBQcmVzZW5jZS5SZWFkLkFsbCBwcm9maWxlIFNpdGVzLlJlYWRXcml0ZS5BbGwgVGFza3MuUmVhZFdyaXRlIFVzZXIuUmVhZCBVc2VyLlJlYWRCYXNpYy5BbGwgVXNlci5SZWFkV3JpdGUgZW1haWwiLCJzaWduaW5fc3RhdGUiOlsia21zaSJdLCJzdWIiOiJ0cFVQSXhhUG5PUjdMSnZhaURmUy1XZENQUWhidVRzMEdXbmNyeU5iamFBIiwidGVuYW50X3JlZ2lvbl9zY29wZSI6Ik9DIiwidGlkIjoiZjdiNWM4NzktMGEwMC00YWVjLWI1YTItNGRkZTViYTc5YWE0IiwidW5pcXVlX25hbWUiOiJhZGFtQGludHVuZS50cmFpbmluZyIsInVwbiI6ImFkYW1AaW50dW5lLnRyYWluaW5nIiwidXRpIjoiVDV6eDhTSmxDRXl5NmJSUzZVd09BQSIsInZlciI6IjEuMCIsIndpZHMiOlsiNjJlOTAzOTQtNjlmNS00MjM3LTkxOTAtMDEyMTc3MTQ1ZTEwIiwiNjQ0ZWY0NzgtZTI4Zi00ZTI4LWI5ZGMtM2ZkZGU5YWEwYjFmIiwiOWI4OTVkOTItMmNkMy00NGM3LTlkMDItYTZhYzJkNWVhNWMzIiwiYjc5ZmJmNGQtM2VmOS00Njg5LTgxNDMtNzZiMTk0ZTg1NTA5Il0sInhtc19zdCI6eyJzdWIiOiJZT2xoRU9xT1BMTG14LVBsS3hMcHhpa0FERFdPTF94eEp2SFVCOE5kQVlNIn0sInhtc190Y2R0IjoxNTU5OTU4MjMzfQ.ltyXyGhKYtcB-BUPd5KFMM3v_ho21z3PBybxzPu-B7wsEP5AtqMN9sB-3kRwrR9wgQvQ9dJsbrNZ7GahLFqbJr4oDBQsJZ91BtcGKnpph2bn0RiGKjsi8MpXFNlgd8Sd6xcuZLd5xjrKQLVCAozrfNqbuUUQ41AjkuBM8Ezgvnn4UB4KAuC5JFFxLkejxiLKMq8KXwct0Uj8GtojQnLpegxyMd2P9j9eTFxn7WHCj0U54IsmzAFcrPgOiza1DL_HshumpYi7EWrozwBe8qdngafEP8CEJsc5DoZNlMlCJ-sphK0ygMps7HlY68vOZe1IjURniPkPCJ0eL8n3_5lWDg"

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
