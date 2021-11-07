Param (
    $AccountSID = "S-1-5-21-2499041169-1956781846-35386737-500",
    [bool]$Disable = $false,
    $Password = "P@ssw0rd"
)

Try {
    $Account = Get-LocalUser -SID $AccountSID
    $Return = @()
    If($Account) {
        If($Disable) {
            If($Account.Enabled) {
                $Account | Disable-LocalUser
                $Return += "Account Disabled"
            }
            Else {
                $Return += "Account Already Diabled"
            }
        }
        Else {
            If(-not $Account.Enabled) {
                $Account | Enable-LocalUser
                $Return += "Account Enabled"
            }
            Else {
                $Return += "Account Already Enabled"
            }
        }
        If($Password) {
            $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
            $Account | Set-LocalUser -Password $SecurePassword
            $Return += "Password Reset"
        }
    }

    $Return
}
Catch {
    Return $Error[0]
}

<#Using NET commands instead
net user Administrator /ACTIVE:YES
net user Administrator P@ssw0rd
#>