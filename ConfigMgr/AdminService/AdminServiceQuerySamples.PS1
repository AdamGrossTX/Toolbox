#AdminService Query Samples - ConfigMgr 1906
Param(
    $SCCMServerName = "CM01.asd.net",
    $CollectionName = "All Systems",
    $CollectionNameFilter = "All",
    $DeviceName="ASD-46637895",
    $UserName = "Adam"
)

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

##1910 TP Only
#Execute WMI Method
#https://Server/AdminService/wmi/SMS_UserMachineRelationship.CreateRelationship
$URL5 = "https://{0}/AdminService/wmi/SMS_UserMachineRelationship.CreateRelationship" -f $SCCMServerName
Write-Host $URL5
$ResourceId = $Result3.value.ResourceId
$SourceID = 6 #OSD Defined
$UserAccountName = $Result4.value.ResourceId
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