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

$ControllerUri = "https://$($SiteServer)/AdminService/v1.0/`$metadata"
$WMIUri = "https://$($SiteServer)/AdminService/wmi/`$metadata"

$agentsquery = New-Object System.Net.WebClient
$agentsquery.Headers.Add('accept','application/xml') 
$agentsquery.UseDefaultCredentials =$true

[XML]$ControllerResults = $agentsquery.DownloadString($ControllerUri)
[XML]$WMIResults = $agentsquery.DownloadString($WMIUri)


#$ControllerClasses = ($ControllerResults | ConvertFrom-Json).value
#$WMIClasses = ($WMIResults | ConvertFrom-Json).value

#Write-Host "Controller Classes" -ForegroundColor Green
#$ControllerClasses | Out-GridView
#Write-Host "WMI Classes" -ForegroundColor Green
#$WMIClasses | Out-GridView    

#Controllers
$ContClasses = $ControllerResults.Edmx.DataServices.Schema.EntityType
$ContFunctions = $ControllerResults.Edmx.DataServices.Schema.Function
$ContActions = $ControllerResults.Edmx.DataServices.Schema.Action
$ContContainers = $ControllerResults.Edmx.DataServices.Schema.EntityContainer

Write-Host "Classes" -ForegroundColor Green
$ContClasses | Format-Table
Write-Host "Functions" -ForegroundColor Green
$ContFunctions| Format-Table
Write-Host "Actions" -ForegroundColor Green
$ContActions| Format-Table
Write-Host "Containers" -ForegroundColor Green
$ContContainers| Format-Table

#WMI
$wmiSchema = $WMIResults.Edmx.DataServices.Schema | Format-Table
$wmiClasses = $WMIResults.Edmx.DataServices.Schema.EntityType | Format-Table
$wmiComplexClasses = $WMIResults.Edmx.DataServices.Schema.ComplexType | Format-Table
$wmiContainers = $WMIResults.Edmx.DataServices.Schema.EntityContainer | Format-Table

Write-Host "Schema" -ForegroundColor Green
$wmiSchema | Format-Table
Write-Host "Classes" -ForegroundColor Green
$wmiClasses | Format-Table
Write-Host "ComplexClasses" -ForegroundColor Green
$wmiComplexClasses | Format-Table
Write-Host "Containers" -ForegroundColor Green
$wmiContainers| Format-Table


#You can add a foreach loop on each object to get the properties for each entity. 
