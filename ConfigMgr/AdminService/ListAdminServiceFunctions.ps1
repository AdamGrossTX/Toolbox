$Credential = Get-Credential
$SCCMServerName = "localhost"
$URL = "http://$($SCCMServerName):80/AdminService/v2/"
$Result = Invoke-RestMethod -Method Get -Uri "$($URL)" -Credential $Credential
$Result
$Result.value.Name #Returns Function Names
