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

#Use this code for the 1902/1902  AdminService
###############
#Sample script for returning AdminService classes
# By: Adam Gross
# @AdamGrossTX
# https://www.asquaredozen.com
###############

####Use this don't use these if you are using the Invoke-RestMethod cmdlets
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#$agentsquery = New-Object System.Net.WebClient
#$agentsquery.Headers.Add('accept','application/xml') 
#$agentsquery.UseDefaultCredentials =$true

#[XML]$ControllerResults = $agentsquery.DownloadString($ControllerUri)
#[XML]$WMIResults = $agentsquery.DownloadString($WMIUri)
################

<#
$SiteServer = "cm01.asd.net"
$BaseUri = "https://$($SiteServer)/AdminService"

$ControllerUri = "https://$($SiteServer)/AdminService/v1.0/`$metadata"
$WMIUri = "https://$($SiteServer)/AdminService/wmi/`$metadata"

$WMIResults = Invoke-RestMethod -Method Get -Uri "$($WMIUri)" -UseDefaultCredentials
$ControllerResults = Invoke-RestMethod -Method Get -Uri "$($ControllerUri)" -UseDefaultCredentials

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
$wmiSchema = $WMIResults.Edmx.DataServices.Schema | Format-List
$wmiClasses = $WMIResults.Edmx.DataServices.Schema.EntityType | Format-Table
$wmiComplexClasses = $WMIResults.Edmx.DataServices.Schema.ComplexType | Format-Table
$wmiContainers = $WMIResults.Edmx.DataServices.Schema.EntityContainer | Format-Table
#>

Function Get-AdminServiceDetails {
    Param(
        $ServerName,
        $ClassType,
        [switch]$Metadata=$true
    )

    $ClassTypeURI = Switch($ClassType)
    {
        "WMI" {"wmi"; Break;}
        "Controller" {"v1.0"; Break;}
    }

    If($Metadata) {
        $BaseURI = "https://{0}/AdminService/{1}/{2}" -f $SiteServer,$ClassTypeURI,"`$metadata"
    }
    Else {
        $BaseURI = "https://{0}/AdminService/{1}/" -f $SiteServer,$ClassTypeURI
    }

    $Results = Invoke-RestMethod -Method Get -Uri "$($BaseURI)" -UseDefaultCredentials
    $Results
}

#You can add a foreach loop on each object to get the properties for each entity. 

#$ControllerClasses = ($ControllerResults | ConvertFrom-Json).value
#$WMIClasses = ($WMIResults | ConvertFrom-Json).value

#Write-Host "Controller Classes" -ForegroundColor Green
#$ControllerClasses | Out-GridView
#Write-Host "WMI Classes" -ForegroundColor Green
#$WMIClasses | Out-GridView    

& $Main