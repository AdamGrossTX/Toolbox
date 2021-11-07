If(!($Credential)) {
    $Credential = Get-Credential
}

$Result = Invoke-WebRequest -Uri "https://ConfigMgr-asdlab1.msappproxy.net/AdminService/v1.0" -Credential $Credential
$ResObj =  ConvertFrom-Json $Result.Content
$ResObj.value

$Result = Invoke-WebRequest -Uri "https://ConfigMgr-asdlab1.msappproxy.net/AdminService/wmi/SMS_R_System" -Credential $Credential
$ResObj =  ConvertFrom-Json $Result.Content
$ResObj.Value.Name

