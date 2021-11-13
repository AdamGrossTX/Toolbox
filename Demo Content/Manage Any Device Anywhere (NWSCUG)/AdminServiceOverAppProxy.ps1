<#
.NOTES
    Author:           Adam Gross - @AdamGrossTX
    GitHub:           https://www.github.com/AdamGrossTX
    WebSite:          https://www.asquaredozen.com

#>
If(!($Credential)) {
    $Credential = Get-Credential
}

$Result = Invoke-WebRequest -Uri "https://configmgradminservice-asdlab1.msappproxy.net/AdminService/v1.0/AdminService/v1.0" -Credential $Credential
$ResObj =  ConvertFrom-Json $Result.Content
$ResObj.value

$Result = Invoke-WebRequest -Uri "https://configmgradminservice-asdlab1.msappproxy.net/AdminService/v1.0/AdminService/wmi/SMS_R_System" -Credential $Credential
$ResObj =  ConvertFrom-Json $Result.Content
$ResObj.Value.Name

