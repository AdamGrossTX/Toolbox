param (
    $RegPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate",
    [switch]$Remediate = $true
)

try {
    if (Test-Path Registry::$RegPath -ErrorAction SilentlyContinue) {
        if ($remediate) {
            Remove-Item Registry::$RegPath -Recurse
        }
        else {
            Write-Host "Reg Key Found. Remediation Needed."
            Exit 1
        }
    }
}
catch {
    throw $_
}
