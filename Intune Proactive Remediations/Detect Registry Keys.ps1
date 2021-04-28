param (

    $Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient",
    $Name = "SearchList",
    $Type = "String",
    $Value = "asd.net",
    [bool]$Remediate = $false
)

Try {
    $Registry = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $Name -ErrorAction SilentlyContinue
    If ($Registry -eq $Value){
        Write-Output "Compliant"
        Exit 0
    }
    Else {
        If ($Remediate -eq $true) {
            $NewKey = New-Item -Path $Path -Force | New-ItemProperty -Name $Name -Value $Value -Force -PropertyType $Type
            If($NewKey.$Name -eq $Value) {
                Write-Output "New Key Created"
                Exit 0
            }
            Else {
                Write-Warning "The new key is invalid."
                Exit 1
            }
        }
        Else {
            Write-Warning "Not Compliant"
            Exit 1
        }
    }
} 
Catch {
    Write-Warning $_
    Exit 1
}