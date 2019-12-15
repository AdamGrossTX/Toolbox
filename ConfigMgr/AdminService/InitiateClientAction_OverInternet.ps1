Param (
    [Parameter(Mandatory=$True, HelpMessage = "Home > App registrations > (Your Native App) - Overview. Copy the Application (client) ID")]
    [string]
    $ClientID,

    [Parameter(Mandatory=$True, HelpMessage = "Home > App registrations > (Your Native App) - Overview. Copy the Directory (tenant) ID")]
    [string]
    $TenantID,

    [Parameter(Mandatory=$True, HelpMessage = "Home > App registrations > (Your Cloud Mangement App) - Authentication. Copy the Redirect URI. It should start with ms-appx-web://")]
    [string]
    $RedirectURI,

    [Parameter(Mandatory=$True, HelpMessage = "Home > App registrations > (Your Cloud Mangement App) - Expose an API. Copy the Application ID URI")]
    [string]
    $ResourceAppIdURI,

    [Parameter(Mandatory=$True, HelpMessage = "Query your SCCM DB - SELECT ExternalEndpointName, ExternalUrl FROM vProxy_Routings WHERE ExternalEndpointName = 'AdminService'")]
    [string]
    $InternetBaseURL,

    [Parameter(Mandatory=$True, HelpMessage = "The URL to your AdminService server https://<FQDN>/AdminService")]
    [string]
    $InternalBaseURL,

    [Parameter(Mandatory=$True, HelpMessage = "Use Token Auth or Current User Auth")]
    [switch]
    $UseTokenAuth = $True,

    [Parameter(Mandatory=$True)]
    [uint64[]]$TargetResourceIDs,

    [Parameter(Mandatory=$True)]
    [string]$TargetCollectionID

)

$Main = {
    [Switch]$TryTokenAuth = $false
    If(!($UseTokenAuth.IsPresent)) {
        Try {
            $Data = Initiate-ClientAction -URL $InternetBaseURL -TargetResourceIDs $TargetResourceIDs -TargetCollectionID $TargetCollectionID
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
        $Data = Initiate-ClientAction -URL $InternetBaseURL -TargetResourceIDs $TargetResourceIDs -TargetCollectionID $TargetCollectionID -authHeader $authHeader
    }
    
    Return $Data.value
}

Function Initiate-ClientAction {
    Param (
        [Parameter(Mandatory=$true,HelpMessage="Enter your server name where AdminService is runnning (SMS Provider Role")]
        [string]$URL,

        [Parameter(Mandatory=$true,HelpMessage="Enter the ResourceID of the target device")]
        [uint32[]]$TargetResourceIDs,

        [Parameter(Mandatory=$false,HelpMessage="Enter a Collection ID that the target device is in")]
        [string]$TargetCollectionID,
        
        $authHeader
    )
    
    $Types = [Ordered]@{
        "DownloadComputerPolicy" = 8
        "DownloadUserPolicy" = 9
        "CollectDiscoveryData" = 10
        "CollectSoftwareInventory" = 11
        "CollectHardwareInventory" = 12
        "EvaluateApplicationDeployments" = 13
        "EvaluateSoftwareUpdateDeployments" = 14
        "SwitchToNextSoftwareUpdatePoint" = 15
        "EvaluateDeviceHealthAttestation" = 16
        "CheckConditionalAccessCompliance" = 125
        "WakeUp" = 150
        "Restart" = 17
        "EnableVerboseLogging" = 20
        "DisableVerboseLogging" = 21
    }

    [uint32]$RandomizationWindow = 1
    [string]$MethodClass = "SMS_ClientOperation"
    [string]$MethodName = "InitiateClientOperation"
    [string]$ResultClass = "SMS_ClientOperationStatus"

    $Types.Keys | ForEach-Object {Write-Host $Types[$_] : $_}
    [uint32]$Type = Read-Host -Prompt "Which client action?"

    $PostURL = "{0}/wmi/{1}.{2}" -f $URL,$MethodClass,$MethodName
    
    $Headers = @{
        "Content-Type" = "Application/json"
    }
    $Body = @{
        TargetCollectionID = $TargetCollectionID
        Type = $Type
        RandomizationWindow = $RandomizationWindow
        TargetResourceIDs = $TargetResourceIDs
    } | ConvertTo-Json
    
    If($authHeader) {
        Invoke-RestMethod -Method Post -Uri "$($PostURL)" -Body $Body -Headers $authHeader | Select-Object ReturnValue
    }
    Else {
        Invoke-RestMethod -Method Post -Uri "$($PostURL)" -Body $Body -Headers $Headers -UseDefaultCredentials | Select-Object ReturnValue
    }


    #Get Results
    $GetURL = "{0}/wmi/{1}" -f $URL,$ResultClass
    
    If($authHeader) {
        $Result = (Invoke-RestMethod -Method Get -Uri "$($GetURL)" -Headers $authHeader).Value | Format-Table
    }
    Else {
        (Invoke-RestMethod -Method Get -Uri "$($GetURL)" -Headers $Headers -UseDefaultCredentials).Value | Format-Table
    }
    Return $Result
}

#Modified Script from Sandy's blog post
#https://www.scconfigmgr.com/2019/07/16/use-configmgr-administration-service-adminservice-over-internet/
#Follow the instructions in her blog post for building a custom App for the AdminService.
#You TECHNICALLY can use the Native Client App that gets created when you build your CMG, but it's 
#Better to create a custom App instead of hijacking the built in one.
Function Get-AADAuthToken {
    Param (
        [Parameter(Mandatory=$True, HelpMessage = "Home > App registrations > (Your Native App) - Overview. Copy the Application (client) ID")]
        [string]
        $ClientID,
    
        [Parameter(Mandatory=$True, HelpMessage = "Home > App registrations > (Your Native App) - Overview. Copy the Directory (tenant) ID")]
        [string]
        $TenantID,
    
        [Parameter(Mandatory=$True, HelpMessage = "Home > App registrations > (Your Cloud Mangement App) - Authentication. Copy the Redirect URI. It should start with ms-appx-web://")]
        [string]
        $RedirectURI,
    
        [Parameter(Mandatory=$True, HelpMessage = "Home > App registrations > (Your Cloud Mangement App) - Expose an API. Copy the Application ID URI")]
        [string]
        $ResourceAppIdURI,
    
        [Parameter(Mandatory=$True, HelpMessage = "Change the prompt behaviour to force credentials each time. https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx.")]
        [ValidateSet("Auto", "Always", "Never", "RefreshSession")]
        [string]
        $PromptForNewCredentials = "Auto"
    )
    
        #Get AAD Token for AdminService
        If(Test-Path "$($PSScriptRoot)\Auth.Json") {
            $AuthToken = Get-Content -Path "$($PSScriptRoot)\Auth.Json" | ConvertFrom-Json
            If(($AuthToken -and (Get-Date) -lt $AuthToken.ExpiresOn)) {
                Return $AuthToken
            }
        }
        If(($AuthToken -and (Get-Date) -ge $AuthToken.ExpiresOn) -or (!(Test-Path "$($PSScriptRoot)\Auth.Json"))) {
            
            $Authority = "https://login.microsoftonline.com/$($TenantID)/oauth2/v2.0/authorize"
    
            $AadModule = Get-Module -Name "AzureAD" -ListAvailable
            If ($AadModule -eq $null)
            {
                Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
                $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable
            }
            If ($AadModule -eq $null)
            {
                Write-Error "AzureAD Powershell module not installed..."
                Write-Error "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt"
                Exit
            }
    
            If ($AadModule.count -gt 1)	{
                $Latest_Version = ($AadModule | Select-Object version | Sort-Object)[-1]
                $aadModule = $AadModule | ForEach-Object { $_.version -eq $Latest_Version.version }
                
                If ($AadModule.count -gt 1)
                {
                    $aadModule = $AadModule | Select-Object -Unique
                }
                $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
                $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
            }
            Else {
                $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
                $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
            }
    
            [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
            [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
    
            Try
            {
                $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
                
                $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList $PromptForNewCredentials
                $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI, $clientId, $redirectUri, $platformParameters).Result
    
                # If the accesstoken is valid save a Json File
                If ($authResult.AccessToken) {
                    $authResult | ConvertTo-Json | Out-File -FilePath "$($PSScriptRoot)\Auth.Json" -Force
                    return $authResult
                }
                Else {
                    Write-Error "Authorization Access Token is null, please re-run authentication..."
                    break
                }
            }
            Catch
            {
                Write-Error $_.Exception.Message
                Write-Error $_.Exception.ItemName
                Break
            }
        }
    }

& $Main