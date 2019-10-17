#AdminService Query Samples - ConfigMgr 1906
Param(
    $SCCMServerName = "CM01.asd.net",
    $CollectionName = "OSD",
    $CollectionNameFilter = "All"
)

#Get Collection by Name
$URL = "https://{0}/AdminService/wmi/SMS_Collection?`$filter=Name eq '{1}'" -f $SCCMServerName,$CollectionName
$Result1 = Invoke-RestMethod -Method Get -Uri "$($URL)" -UseDefaultCredentials
$Result1.value.Name #Returns collection Names

#Get Collections by Name Filter
$URL2 = "https://{0}/AdminService/wmi/SMS_Collection?`$filter=contains(Name,'{1}')" -f $SCCMServerName,$CollectionNameFilter
$Result2 = Invoke-RestMethod -Method Get -Uri "$($URL2)" -UseDefaultCredentials
$Result2.value.Name #Returns collection Names