#WORK IN PROGRESS>DO NOT USE
#Azure Function for Azure Monitor Log Ingestion API
using namespace System.Net
param (
    $Request, 
    $TriggerMetadata
)
Write-Host "PowerShell HTTP trigger function processed a request."

$LogParams = @{
    DceURI = $Request.Query.DceURI
    DcrImmutableId = $Request.Query.DcrImmutableId
    Table = $Request.Query.Table
    LogEntry = $Request.Query.LogEntry
}

$authParams = @{
    tenant_id     = $env:tenant_id
    client_id     = $env:client_id
    client_secret = $env:client_secret
    resource_url  = "https://monitor.azure.com"
}

function Get-AuthHeader {
    param (
        [Parameter(mandatory = $true)]
        [string]$tenant_id,
        [Parameter(mandatory = $true)]
        [string]$client_id,
        [Parameter(mandatory = $true)]
        [string]$client_secret,
        [Parameter(mandatory = $true)]
        [string]$resource_url,
        [Parameter(mandatory = $true)]
        [string]$scope
        
    )
    $body = @{
        resource      = $resource_url
        client_id     = $client_id
        client_secret = $client_secret
        grant_type    = "client_credentials"
        scope         = $scope = [System.Web.HttpUtility]::UrlEncode("$($scope)//.default")   
    }
    try {
        $response = Invoke-RestMethod -Method post -Uri "https://login.microsoftonline.com/$tenant_id/oauth2/token" -Body $body -ErrorAction Stop
        $headers = @{ }
        $headers.Add("Authorization", "Bearer " + $response.access_token)
        return $headers
    }
    catch {
        Write-Error $_.Exception
    }
}

function Invoke-LogUpload {
    param(
        $DceURI,
        $DcrImmutableId,
        $Table,
        $LogEntry,
        $Header
    )
    
    $params = @{
        Body        = $LogEntry | ConvertTo-Json -AsArray -Depth 10
        Uri         = "$($DceURI)/dataCollectionRules/$($DcrImmutableId)/streams/Custom-$($Table)?api-version=2021-11-01-preview"
        Method      = "Post"
        Headers     = $Header
        ContentType = "application/json"
    }

    $uploadResponse = Invoke-RestMethod @Params
    return $uploadResponse
}

$header = Get-AuthHeader @authParams
$result = Invoke-LogUpload @logParams -Header $Header

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $status
        Body       = $result
    })
#endregion
