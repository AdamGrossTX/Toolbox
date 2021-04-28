#AdminService Query Samples - ConfigMgr 1906
Param(
    [Parameter(Mandatory=$false)]
    [string]
    $SCCMServerName,

    [Parameter(Mandatory=$false)]
    [string]
    $DeviceName,

    [Parameter(Mandatory=$false)]
    [string]
    $UserName

    [Parameter(Mandatory=$false)]
    [string]
    $AppName
)

<#
$SCCMServerName = "CM01.ASD.NET"
$DeviceName="ASD-MyDevice"
$UserName = "Adam"
$AppName = "Google Chrome for Enterprise 60.0.3112.90"
#>


#Get Specific Device
$URL3 = "https://{0}/AdminService/wmi/SMS_R_System?`$filter=Name eq '{1}'" -f $SCCMServerName,$DeviceName
Write-Host $URL3
$Result3 = Invoke-RestMethod -Method Get -Uri "$($URL3)" -UseDefaultCredentials
$Result3 | ConvertTo-Json
$Result3.value.ResourceId #Returns Device ResourceIDs

#Get Application
$URL1 = "https://{0}/AdminService/wmi/SMS_ApplicationLatest?`$filter=LocalizedDisplayName eq '{1}'" -f $SCCMServerName,$AppName
Write-Host $URL1
$Result1 = Invoke-RestMethod -Method Get -Uri "$($URL1)" -UseDefaultCredentials
$Result1 | ConvertTo-Json
$Result1.value.CI_UniqueID #Returns Device ResourceIDs

$URL6 = "https://{0}/AdminService/wmi/SMS_ApplicationRequest.CreateApprovedRequest" -f $SCCMServerName
Write-Host $URL6
$ClientGUID = $Result3.value.SMSUniqueIdentifier
$ModelName = $Result1.value.ModelName #Returns Device ResourceIDs
$Headers = @{
    "Content-Type" = "Application/json"
}
$Params = @{
    ApplicationId = $ModelName
    AutoInstall = $True
    ClientGUID = $ClientGUID
    Comments = "This is a test from the AdminService"
    Username = $null
}

$RequestBody = $Params | ConvertTo-Json 

Write-Host $RequestBody
Write-Host "$($URL6)"
Invoke-RestMethod -Method Post -Uri "$($URL6)" -Body $RequestBody -UseDefaultCredentials -Headers $Headers



#Get Application
$URL1 = "https://{0}/AdminService/wmi/SMS_ApplicationRequest?`$filter=LocalizedDisplayName eq '{1}'" -f $SCCMServerName,$AppName
Write-Host $URL1
$Result1 = Invoke-RestMethod -Method Get -Uri "$($URL1)" -UseDefaultCredentials
$Result1 | ConvertTo-Json
$Result1.value.CI_UniqueID #Returns Device ResourceIDs



$URL7 = "https://{0}/AdminService/wmi/SMS_ApplicationRequest" -f $SCCMServerName
Write-Host $URL7
$ClientGUID = $Result.value.SMSUniqueIdentifier
$ModelName = $Result1.value.ModelName #Returns Device ResourceIDs
$Headers = @{
    "Content-Type" = "Application/json"
}
$Params = @{
    ApplicationId = $ModelName
    AutoInstall = $True
    ClientGUID = $ClientGUID
    Comments = "This is a test from the AdminService"
    Username = $null
}

$RequestBody = $Params | ConvertTo-Json 

Write-Host $RequestBody
Write-Host "$($URL6)"
Invoke-RestMethod -Method Post -Uri "$($URL6)" -Body $RequestBody -UseDefaultCredentials -Headers $Headers


$URL = "https://cm01/AdminService/wmi/SMS_ApplicationRequest('8C65F00A-4F0A-4B39-9665-99835089DFB0')/Approve"

$Headers = @{
    "Content-Type" = "Application/json"
}
$Params = @{
    ClientSource = 18
    Comments = ''
}

$RequestBody = $Params | ConvertTo-Json 

Write-Host $RequestBody
Write-Host "$($URL)"
#Invoke-RestMethod -Method Post -Uri "$($URL)" -UseDefaultCredentials -Headers $Headers

Invoke-RestMethod -Method Post -Uri "$($URL)" -Body $RequestBody -UseDefaultCredentials -Headers $Headers


$Results = Invoke-RestMethod -Method Get -Uri "https://cm01/AdminService/wmi/`$metadata" -UseDefaultCredentials -Headers $Headers

