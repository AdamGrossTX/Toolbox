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

#Current Code for CB 1906
$Main = {
    $ControllerResults = Get-AdminServiceDetails -ServerName 'CM01' -ClassType 'Controller'
    $WMIResults = Get-AdminServiceDetails -ServerName 'CM01' -ClassType 'WMI'

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

    Write-Host "Schema" -ForegroundColor Green
    $wmiSchema | Format-Table
    Write-Host "Classes" -ForegroundColor Green
    $wmiClasses| Format-Table
    Write-Host "ComplexClasses" -ForegroundColor Green
    $wmiComplexClasses| Format-Table
    Write-Host "Containers" -ForegroundColor Green
    $wmiContainers| Format-Table


}
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
        $BaseURI = "https://{0}/AdminService/{1}/{2}" -f $ServerName,$ClassTypeURI,"`$metadata"
    }
    Else {
        $BaseURI = "https://{0}/AdminService/{1}/" -f $ServerName,$ClassTypeURI
    }

    $Results = Invoke-RestMethod -Method Get -Uri "$($BaseURI)" -UseDefaultCredentials
    Return $Results
}

#You can add a foreach loop on each object to get the properties for each entity. 

#$ControllerClasses = ($ControllerResults | ConvertFrom-Json).value
#$WMIClasses = ($WMIResults | ConvertFrom-Json).value

#Write-Host "Controller Classes" -ForegroundColor Green
#$ControllerClasses | Out-GridView
#Write-Host "WMI Classes" -ForegroundColor Green
#$WMIClasses | Out-GridView    

& $Main