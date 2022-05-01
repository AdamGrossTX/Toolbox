<#
.NOTES
    Author:           Adam Gross - @AdamGrossTX
    GitHub:           https://www.github.com/AdamGrossTX
    WebSite:          https://www.asquaredozen.com

#>
#AdminService Query Samples - ConfigMgr 1906
Param(
    [Parameter(Mandatory=$false)]
    [string]
    $SCCMServerName,

    [Parameter(Mandatory=$false)]
    [string]
    $CollectionName,

    [Parameter(Mandatory=$false)]
    [string]
    $CollectionNameFilter,

    [Parameter(Mandatory=$false)]
    [string]
    $DeviceName,

    [Parameter(Mandatory=$false)]
    [string]
    $UserName
)

#CB
$SCCMServerName = "AS01.asd.net"
$CollectionName = "All Systems"
$CollectionNameFilter = "All"
$DeviceName="ASD-50124588"
$UserName = "Adam"

#TP
#$SCCMServerName = "CMTP3-CM1.asd.lab"
#$CollectionName = "All Systems"
#$CollectionNameFilter = "All"
#$DeviceName="CMTP3-CM1"
#$UserName = "Adam"

#Get Collection by Name
$URL1 = "https://{0}/AdminService/wmi/SMS_Collection?`$filter=Name eq '{1}'" -f $SCCMServerName,$CollectionName
Write-Host $URL1
$Result1 = Invoke-RestMethod -Method Get -Uri "$($URL1)" -UseDefaultCredentials
$Result1.value.Name #Returns collection Names

#Get Collections by Name Filter
$URL2 = "https://{0}/AdminService/wmi/SMS_Collection?`$filter=contains(Name,'{1}')" -f $SCCMServerName,$CollectionNameFilter
Write-Host $URL2
$Result2 = Invoke-RestMethod -Method Get -Uri "$($URL2)" -UseDefaultCredentials
$Result2 | ConvertTo-Json
$Result2.value.Name #Returns collection Names

#Get Specific Device
$URL3 = "https://{0}/AdminService/wmi/SMS_R_System?`$filter=Name eq '{1}'" -f $SCCMServerName,$DeviceName
Write-Host $URL3
$Result3 = Invoke-RestMethod -Method Get -Uri "$($URL3)" -UseDefaultCredentials
$Result3 | ConvertTo-Json
$Result3.value.ResourceId #Returns Device ResourceIDs

#Get Specific User
$URL4 = "https://{0}/AdminService/wmi/SMS_R_User?`$filter=contains(Name,'{1}')" -f $SCCMServerName,$UserName
Write-Host $URL4
$Result4 = Invoke-RestMethod -Method Get -Uri "$($URL4)" -UseDefaultCredentials
$Result4 | ConvertTo-Json
$Result4.value.ResourceId #Returns Device ResourceIDs


$URL7 = "https://{0}/AdminService/wmi/SMS_Package" -f $SCCMServerName
Write-Host $URL7
$Headers = @{
    "Content-Type" = "Application/json"
}
$Params = @{
    "Name" = "Test Package"
    "Manufacturer" = "ASD"
    "PackageID" = "PS100062"
}
$RequestBody = $Params | ConvertTo-Json 

Write-Host $RequestBody
Write-Host "$($URL7)"
$Result = Invoke-RestMethod -Method Post -Uri "$($URL7)" -Body $RequestBody -UseDefaultCredentials -Headers $Headers


##################################################################
##1910 TP Only
#Execute WMI Method
#https://Server/AdminService/wmi/SMS_UserMachineRelationship.CreateRelationship
$URL5 = "https://{0}/AdminService/wmi/SMS_UserMachineRelationship.CreateRelationship" -f $SCCMServerName
Write-Host $URL5
$ResourceId = $Result3.value.ResourceId
$SourceID = 6 #OSD Defined
$UserAccountName = $Result4.value.UniqueUserName
$Headers = @{
    "Content-Type" = "Application/json"
}
$Params = @{
    MachineResourceId = $ResourceId
    SourceId = $SourceID
    TypeId = 1
    UserAccountName = "$($UserAccountName)"
}
$RequestBody = $Params | ConvertTo-Json 

Write-Host $RequestBody
Write-Host "$($URL5)"
Invoke-RestMethod -Method Post -Uri "$($URL5)" -Body $RequestBody -UseDefaultCredentials -Headers $Headers

$URL6 = "https://{0}/AdminService/wmi/SMS_ApplicationRequest.CreateApprovedRequest" -f $SCCMServerName
Write-Host $URL6
$ClientGUID = $Result3.value.SMSUniqueIdentifier
$UserName = $Result4.value.UniqueUserName
$Result3.value
$Headers = @{
    "Content-Type" = "Application/json"
}
$Params = @{
    ApplicationId = "ScopeId_68DCD582-5CAE-4DC2-BFD4-4DA40B2452B5/Application_78fcd81d-3968-41cf-9433-da8559784d98"
    AutoInstall = $True
    ClientGUID = $ClientGUID
    Comments = "This is a test from the AdminService"
    Username = $null
}

$RequestBody = $Params | ConvertTo-Json 

Write-Host $RequestBody
Write-Host "$($URL6)"
Invoke-RestMethod -Method Post -Uri "$($URL6)" -Body $RequestBody -UseDefaultCredentials -Headers $Headers


#Get-CIMInstance -Namespace root\sms\site_tp3 -ClassName SMS_ApplicationRequest | Remove-CIMInstance