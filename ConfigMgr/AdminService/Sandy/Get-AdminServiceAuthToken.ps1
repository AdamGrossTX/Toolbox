Param (
    $clientId = "e9d07887-a8df-43ac-88dd-8db59f1aa37a", #Change this to your own AdminService App ID
    $TenantID = "86c2857f-9fb5-4b97-bf85-87c2f8ca9ff5", #Change this to your own tenant ID
    $resourceAppIdURI = "https://asdclougmgmt.ConfigMgrService", #Change this to your own resource app ID URL
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob",
    $Baseurl = "https://asquaredozencloudservice.asquaredozen.com/CCM_Proxy_ServerAuth/72057594037927941/AdminService"
)

$Main = {

#Ignore self-signed certificate checks
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type) {
$certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@

Add-Type $certCallback
     }
     [ServerCertificateValidationCallback]::Ignore()
    
    #Get AAD Token for AdminService
    $authToken = Get-AdminServiceAuthToken -ClientID $ClientID -TenantID $TenantID -ResourceAppIDURI $ResourceAppIDURI
    
    $authToken | Format-List
    #AdminService endpoint, get ConfigMgr SMS_R_User infor
    
    #$URL = $BaseURL + "/v1.0/SMS_CMPivotStatus"
    $URL = "https://cm01.asd.net/ADMINSERVICE_TOKENAUTH/wmi/Sms_r_System"
    
    # Make REST API call
    $Data = Invoke-RestMethod -Method Get -Uri $url -Headers $authToken -Verbose
    $Data = Invoke-RestMethod -Method Get -Uri $url -Headers $authToken -Verbose
    $Data.value
}

function Get-AdminServiceAuthToken {
    Param(
        $ClientID,
        $TenantID,
        $ResourceAppIDURI
    )
    
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    $authority = "https://login.microsoftonline.com/$($TenantID)/oauth2/v2.0/authorize"

	$AadModule = Get-Module -Name "AzureAD" -ListAvailable
	if ($AadModule -eq $null)
	{
		Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
		$AadModule = Get-Module -Name "AzureADPreview" -ListAvailable
	}
	if ($AadModule -eq $null)
	{
		Write-Error "AzureAD Powershell module not installed..."
		Write-Error "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt"
		exit
	}
	
	# Getting path to ActiveDirectory Assemblies
	# If the module count is greater than 1 find the latest version
	
	if ($AadModule.count -gt 1)
	{
		$Latest_Version = ($AadModule | Select-Object version | Sort-Object)[-1]
		$aadModule = $AadModule | ForEach-Object { $_.version -eq $Latest_Version.version }
		
		# Checking if there are multiple versions of the same module found		
		if ($AadModule.count -gt 1)
		{
			$aadModule = $AadModule | Select-Object -Unique
		}
		$adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
		$adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
	}
	else
	{
		$adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
		$adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
	}
	
	[System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
	[System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
	
 
	try
	{
		$authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
		
		# https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
		# Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession
		
		$platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Always"
		$authResult = $authContext.AcquireTokenAsync($resourceAppIdURI, $clientId, $redirectUri, $platformParameters).Result

		
		# If the accesstoken is valid then create the authentication header		
		if ($authResult.AccessToken)
		{
			# Creating header for Authorization token			
			$authHeader = @{
				'Content-Type'  = 'application/json'
				'Authorization' = "Bearer " + $authResult.AccessToken
				'ExpiresOn'	    = $authResult.ExpiresOn
			}
			return $authHeader
		}
		else
		{
			Write-Error "Authorization Access Token is null, please re-run authentication..."
			break
		}
	}
	catch
	{
		Write-Error $_.Exception.Message
		Write-Error $_.Exception.ItemName
		break
	}
}

& $Main

