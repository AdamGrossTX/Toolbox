###############
#Sample script for returning AdminService classes
# By: Adam Gross
# @AdamGrossTX
# https://www.asquaredozen.com
# https://github.com/AdamGrossTX
###############
[cmdletbinding()]
param(
    [parameter(Mandatory=$true)]
    [String]$SiteServer
)
$Main = {
    $ControllerResults = Get-AdminServiceDetails -ServerName $SiteServer -ClassType 'Controller'
    $WMIResults = Get-AdminServiceDetails -ServerName $SiteServer -ClassType 'WMI'

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
    $wmiSchema = $WMIResults.Edmx.DataServices.Schema
    $wmiClasses = $WMIResults.Edmx.DataServices.Schema.EntityType
    $wmiComplexClasses = $WMIResults.Edmx.DataServices.Schema.ComplexType
    $wmiContainers = $WMIResults.Edmx.DataServices.Schema.EntityContainer
    $wmiActionImport = $WMIResults.Edmx.DataServices.Schema.EntityContainer.ActionImport

    Write-Host "Schema" -ForegroundColor Green
    $wmiSchema | Format-Table
    Write-Host "Classes" -ForegroundColor Green
    $wmiClasses | Out-GridView 
    #| Format-Table
    Write-Host "ComplexClasses" -ForegroundColor Green
    $wmiComplexClasses | Format-Table
    Write-Host "Containers" -ForegroundColor Green
    $wmiContainers | Format-Table
    Write-Host "ActionImport" -ForegroundColor Green
    $wmiActionImport.Name | Format-Table

}
Function Get-AdminServiceDetails {
    param(
        $ServerName,
        $ClassType,
        [switch]$Metadata=$true
    )

    $ClassTypeURI = switch($ClassType)
    {
        "WMI" {"wmi"; break;}
        "Controller" {"v1.0"; break;}
    }

    if ($Metadata) {
        $BaseURI = "https://{0}/AdminService/{1}/{2}" -f $ServerName,$ClassTypeURI,"`$metadata"
    }
    else {
        $BaseURI = "https://{0}/AdminService/{1}/" -f $ServerName,$ClassTypeURI
    }
    $Results = Invoke-RestMethod -Method Get -Uri "$($BaseURI)" -UseDefaultCredentials
    return $Results
}

#You can add a foreach loop on each object to get the properties for each entity. 

#$ControllerClasses = ($ControllerResults | ConvertFrom-Json).value
#$WMIClasses = ($WMIResults | ConvertFrom-Json).value

#Write-Host "Controller Classes" -ForegroundColor Green
#$ControllerClasses | Out-GridView
#Write-Host "WMI Classes" -ForegroundColor Green
#$WMIClasses | Out-GridView    

& $Main