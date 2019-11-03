Param (
    [Parameter(Mandatory=$False, HelpMessage = "Home > App registrations > (Your Native App) - Overview. Copy the Application (client) ID")]
    [string]
    $ClientID,

    [Parameter(Mandatory=$False, HelpMessage = "Home > App registrations > (Your Native App) - Overview. Copy the Directory (tenant) ID")]
    [string]
    $TenantID,

    [Parameter(Mandatory=$False, HelpMessage = "Home > App registrations > (Your Cloud Mangement App) - Authentication. Copy the Redirect URI. It should start with ms-appx-web://")]
    [string]
    $RedirectURI,

    [Parameter(Mandatory=$False, HelpMessage = "Home > App registrations > (Your Cloud Mangement App) - Expose an API. Copy the Application ID URI")]
    [string]
    $ResourceAppIdURI,

    [Parameter(Mandatory=$False, HelpMessage = "Query your SCCM DB - SELECT ExternalEndpointName, ExternalUrl FROM vProxy_Routings WHERE ExternalEndpointName = 'AdminService'")]
    [string]
    $InternetBaseURL,

    [Parameter(Mandatory=$False, HelpMessage = "The URL to your AdminService server https://<FQDN>/AdminService")]
    [string]
    $InternalBaseURL,

    [Parameter(Mandatory=$False, HelpMessage = "Use Token Auth or Current User Auth")]
    [switch]
    $UseTokenAuth = $True

)
    . (Join-Path -Path $PSScriptRoot -ChildPath "Get-AADAuthToken.ps1")

    # Make REST API call
    $Query = "/wmi/SMS_R_User"

    [Switch]$TryTokenAuth = $false
    If(!($UseTokenAuth.IsPresent)) {
        Try {
            $Data = Invoke-RestMethod -Method Get -Uri "$($InternalBaseURL)$($Query)" -UseDefaultCredentials -ErrorAction SilentlyContinue
        }
        Catch {
            Write-Host "An error occurred using default credentials. Trying with Token Auth."
            $TryTokenAuth = $True
        }
    }

    If($UseTokenAuth.IsPresent -or $TryTokenAuth) {
        $AuthToken = Get-AADAuthToken -ClientID $ClientID -TenantID $TenantID -ResourceAppIDURI $ResourceAppIDURI -RedirectUri $RedirectUri -PromptForNewCredentials Auto
        # Creating header for Authorization token
        If($AuthToken) {
            $AuthHeader = @{
                'Content-Type'  = 'application/json'
                'Authorization' = "Bearer " + $AuthToken.AccessToken
                'ExpiresOn'	    = $AuthToken.ExpiresOn
            }
        }
        Else {
            Write-Host "No Auth Token Found. Exiting."
            Break;
        }
        $Data = Invoke-RestMethod -Method Get -Uri "$($InternetBaseURL)$($Query)" -Headers $authHeader
    }
    
    Return $Data.value