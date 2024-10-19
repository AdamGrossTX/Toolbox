<#
.SYNOPSIS
A collection of helper functions to interact with the Microsoft Graph API using the Microsoft.Graph module.

.DESCRIPTION
This script contains a collection of functions that help you interact with the Microsoft Graph API using the Microsoft.Graph module. The functions include sending GET, POST, PATCH, PUT, and DELETE requests to the Microsoft Graph API, handling pagination, and batching requests. Use the functions in place of Invoke-MGGraphRequest.

.LINK
https://github.com/AdamGrossTX/MGGraphHelperFunctions

.AUTHOR
Adam Gross
@AdamGrossTX

#>


<#
.SYNOPSIS
Executes a GET request to the Microsoft Graph API and handles pagination.

.DESCRIPTION
This function sends a GET request to the specified URI using the Microsoft Graph API.
It handles pagination by following the '@odata.nextLink' property if present.
If the request is throttled, it retries after a specified delay.

.PARAMETER URI
The URI endpoint for the Microsoft Graph API request.

.PARAMETER SkipNextLink
A switch parameter to skip following the '@odata.nextLink' for pagination.

.EXAMPLE
Invoke-GraphGet -URI "https://graph.microsoft.com/v1.0/users"

.NOTES
This function requires the Microsoft.Graph module.
#>
function Invoke-GraphGet {

    [cmdletbinding()]
    param(
        $URI,
        [switch]$SkipNextLink
    )
    try {
        $graphGetParams = @{
            Headers = @{
                "ConsistencyLevel" = "Eventual"
                "Content-Type"     = "application/json"
            }
            Method  = "GET"
            URI     = $URI
        }
        $results = do {
            $response = Invoke-MgRestMethod @graphGetParams
            $graphGetParams.URI = $Response.'@odata.nextLink'
            if ($response.value) {
                $response.value
            }
            else {
                $response
            }
        } until (-not $response.'@odata.nextLink' -or $SkipNextLink.IsPresent)
        return $results
    }
    catch {
        if ($_.Exception.Response -eq 429 -or $_ -like '*TooManyRequests*') {
            [int]$RetryValue = 30
            Write-Warning "WebException Error message! Throttling error. Retry-After header value: $($RetryValue) seconds. Sleeping for $($RetryValue + 1)s"
            Start-Sleep -Seconds $($RetryValue + 1) 
            Invoke-GraphGet -SkipNextLink -URI $graphGetParams.URI -Token $Token
        }
        else {
            throw $_
        }
    }
}

<#
    .SYNOPSIS
    Executes a batch request to the Microsoft Graph API.

    .DESCRIPTION
    This script contains a function that allows you to execute a batch request to the Microsoft Graph API.
    It provides a convenient way to send multiple requests in a single HTTP call, reducing the number of round trips to the server and improving performance.

    .PARAMETER RequestBody
    The batch request object that contains the individual requests to be executed.

    .EXAMPLE
        $RequestBody = @(
            @{
                Id = "1"
                Method = "GET"
                Url = "https://graph.microsoft.com/v1.0/me"
            },
            @{
                Id = "2"
                Method = "GET"
                Url = "https://graph.microsoft.com/v1.0/users"
            }
        )
    
    Invoke-GraphBatch -BatchRequest $batchRequest

    .NOTES
    This script requires the Microsoft.Graph module to be installed.

    .LINK
    https://learn.microsoft.com/en-us/graph/json-batching
#>
function Invoke-GraphBatch {
    
    [cmdletbinding()]
    param (
        $RequestBody
    )
    try {
        $URI = "https://graph.microsoft.com/beta/`$batch"
        $Body = @{
            requests = $RequestBody
        }

        $BatchResponse = Invoke-GraphPost -URI $URI -Body $Body
        $NeedsToRetry = $false
        
        $NeedsToRetry = if ($BatchResponse.responses.status) {
            $BatchResponse.responses.status -contains 429
        }
        elseif ($BatchResponse.Status) {
            $BatchResponse.Status -contains 429
        }
        if ($NeedsToRetry) {
            Start-Sleep -Seconds 25
            Invoke-GraphBatch -RequestBody $RequestBody
        }
        return $BatchResponse
    }
    catch {
        throw $_
    }
}

<#
.SYNOPSIS
    Deletes a resource using the Microsoft Graph API.

.DESCRIPTION
    The Invoke-GraphDelete function sends a DELETE request to the specified URI using the Microsoft Graph API.
    It handles throttling errors by retrying the request after a specified interval.

.PARAMETER URI
    The URI of the resource to be deleted.

.EXAMPLE
    Invoke-GraphDelete -URI "https://graph.microsoft.com/v1.0/users/{user-id}"

    This example deletes a user resource using the Microsoft Graph API.

.NOTES
    This function requires the Invoke-MgRestMethod function to be available in the current session.
#>
function Invoke-GraphDelete {
    [cmdletbinding()]
    param(
        $URI
    )
    try {

        $graphPostParams = @{
            Headers = @{
                "ConsistencyLevel" = "Eventual"
            }
            Method  = "DELETE"
            URI     = $URI
        }
        $response = Invoke-MgRestMethod @graphPostParams
        return $response
    }
    catch {
        if ($_.Exception.Response -eq 429 -or $_ -like '*TooManyRequests*') {
            [int]$RetryValue = 30
            Write-Warning "WebException Error message! Throttling error. Retry-After header value: $($RetryValue) seconds. Sleeping for $($RetryValue + 1)s"
            Start-Sleep -Seconds $($RetryValue + 1) 
            Invoke-GraphDelete -URI $URI
        }
        else {
            throw $_
        }
    }
}

<#
.SYNOPSIS
    Invokes a PATCH request to the Microsoft Graph API.

.DESCRIPTION
    This function sends a PATCH request to the specified URI using the Microsoft Graph API. It includes the provided body in the request payload.

.PARAMETER URI
    The URI of the resource to be updated.

.PARAMETER Body
    The body of the request, which contains the data to be updated.

.EXAMPLE
    $uri = "https://graph.microsoft.com/v1.0/users/{user-id}"
    $body = @{
        displayName = "John Doe"
        jobTitle = "Software Engineer"
    }
    Invoke-GraphPatch -URI $uri -Body $body

    This example invokes a PATCH request to update the display name and job title of a user in the Microsoft Graph API.

.NOTES
    This function handles throttling errors by automatically retrying the request after a specified delay.
#>
function Invoke-GraphPatch {
    [cmdletbinding()]
    param(
        $URI,
        $Body
    )
    try {
        $graphPatchParams = @{
            Headers = @{
                "ConsistencyLevel" = "Eventual"
                "Content-Type"     = "application/json"
            }
            Method  = "PATCH"
            URI     = $URI
            Body    = $Body | ConvertTo-Json -Depth 100
        }
        $response = Invoke-MgRestMethod @graphPatchParams
        return $response
    }
    catch {
        if ($_.Exception.Response -eq 429 -or $_ -like '*TooManyRequests*') {
            [int]$RetryValue = 30
            Write-Warning "WebException Error message! Throttling error. Retry-After header value: $($RetryValue) seconds. Sleeping for $($RetryValue + 1)s"
            Start-Sleep -Seconds $($RetryValue + 1) 
            Invoke-GraphPatch -URI $URI -Body $Body
        }
        else {
            throw $_
        }
    }
}

<#
.SYNOPSIS
    Invokes a POST request to the Microsoft Graph API.

.DESCRIPTION
    This function sends a POST request to the specified URI using the Microsoft Graph API. It includes the provided body in the request payload and sets the necessary headers for consistency and content type.

.PARAMETER URI
    The URI of the Microsoft Graph API endpoint to send the POST request to.

.PARAMETER Body
    The body of the request payload. It will be converted to JSON format using the ConvertTo-Json cmdlet.

.PARAMETER OutputFilePath
    Optional. The file path to save the response content to.

.EXAMPLE
    $uri = "https://graph.microsoft.com/v1.0/users"
    $body = @{
        displayName = "John Doe"
        mail = "johndoe@example.com"
    }
    Invoke-GraphPost -URI $uri -Body $body

.NOTES
    This function handles throttling errors by retrying the request after a specified delay if the error response indicates too many requests (status code 429) or contains the "TooManyRequests" string.

#>
function Invoke-GraphPost {
    [cmdletbinding()]
    param(
        $URI,
        $Body,
        $OutputFilePath
    )
    try {
        $graphPostParams = @{
            Headers = @{
                "ConsistencyLevel" = "Eventual"
                "Content-Type"     = "application/json"
            }
            Method  = "POST"
            URI     = $URI
            Body    = $Body | ConvertTo-Json -Depth 100
        }
        if ($OutputFilePath) {
            $graphPostParams.OutputFilePath = $OutputFilePath
        }
        $response = Invoke-MgRestMethod @graphPostParams -OutputFilePath $OutputFilePath
        return $response
    }
    catch {
        if ($_.Exception.Response -eq 429 -or $_ -like '*TooManyRequests*') {
            [int]$RetryValue = 30
            Write-Warning "WebException Error message! Throttling error. Retry-After header value: $($RetryValue) seconds. Sleeping for $($RetryValue + 1)s"
            Start-Sleep -Seconds $($RetryValue + 1) 
            Invoke-GraphPost -URI $URI -Body $Body -OutputFilePath $OutputFilePath
        }
        else {
            $graphPostParams.Body
            throw $_
        }
    }
}

<#
.SYNOPSIS
    Invokes a PUT request to the Microsoft Graph API.

.DESCRIPTION
    This function sends a PUT request to the specified URI using the Microsoft Graph API. It includes the provided body in the request payload.

.PARAMETER URI
    The URI of the resource to update.

.PARAMETER Body
    The body of the request, which will be converted to JSON format.

.EXAMPLE
    $uri = "https://graph.microsoft.com/v1.0/users/12345"
    $body = @{
        displayName = "John Doe"
        jobTitle = "Software Engineer"
    }
    Invoke-GraphPut -URI $uri -Body $body

.NOTES
    This function handles throttling errors by retrying the request after a specified delay if the error code is 429 or if the error message contains "TooManyRequests".
#>
function Invoke-GraphPut {
    [cmdletbinding()]
    param(
        $URI,
        $Body
    )
    try {
        $graphPutParams = @{
            Headers = @{
                "ConsistencyLevel" = "Eventual"
                "Content-Type"     = "application/json"
            }
            Method  = "PUT"
            URI     = $URI
            Body    = $Body | ConvertTo-Json -Depth 100
        }
        $response = Invoke-MgRestMethod @graphPutParams
        return $response
    }
    catch {
        if ($_.Exception.Response -eq 429 -or $_ -like '*TooManyRequests*') {
            [int]$RetryValue = 30
            Write-Warning "WebException Error message! Throttling error. Retry-After header value: $($RetryValue) seconds. Sleeping for $($RetryValue + 1)s"
            Start-Sleep -Seconds $($RetryValue + 1) 
            Invoke-MgRestMethod -URI $URI -Body $Body
        }
        else {
            throw $_
        }
    }
}