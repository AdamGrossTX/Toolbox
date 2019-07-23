#This code only works for the 1810 TP adminservice
<#
$Credential = Get-Credential
$SCCMServerName = "localhost"
$URL = "http://$($SCCMServerName):80/AdminService/v2/"
$Result = Invoke-RestMethod -Method Get -Uri "$($URL)" -Credential $Credential
$Result
$Result.value.Name #Returns Function Names
#>

#Use this code for the 1906 TP AdminService
###############
#Sample script for returning AdminService classes
# By: Adam Gross
# @AdamGrossTX
# https://www.asquaredozen.com
###############


$SiteServer = "YourServerName"
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ControllerUri = "https://$($SiteServer)/AdminService/v1.0/$metadata"
$WMIUri = "https://$($SiteServer)/AdminService/wmi/$metadata"

$agentsquery = New-Object System.Net.WebClient
$agentsquery.Headers.Add('accept','application/json') 
$agentsquery.UseDefaultCredentials =$true

$ControllerResults = $agentsquery.GetWebResponse($ControllerUri)
$WMIResults = $agentsquery.DownloadString($WMIUri)

$ControllerClasses = ($ControllerResults | ConvertFrom-Json).value
$WMIClasses = ($WMIResults | ConvertFrom-Json).value

#Write-Host "Controller Classes" -ForegroundColor Green
$ControllerClasses | Out-GridView
#Write-Host "WMI Classes" -ForegroundColor Green
$WMIClasses | Out-GridView    
