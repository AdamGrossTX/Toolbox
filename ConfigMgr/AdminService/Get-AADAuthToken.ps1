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