$Credential = Get-Credential
$SCCMServerName = "localhost"
$Function = "Collection" #Change this to whatever you want to query.
$URL = "http://$($SCCMServerName):80/AdminService/v2/$($Function)"
$Result = Invoke-RestMethod -Method Get -Uri "$($URL)" -Credential $Credential
$Result
$Result.value.Name #Returns collection Names
