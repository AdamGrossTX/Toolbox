[CmdletBinding()]
param(
    [version]$ExpectedTPMVersion = "1.1.0"
)

try {
    if(-not $ExpectedTPMVersion) {
        Return $true
    }
    $TPM = Get-CimInstance -Namespace "root\CIMV2\Security\MicrosoftTpm" -ClassName "Win32_Tpm" -ErrorAction SilentlyContinue
    [bool]$retVal = $false
    if ($TPM) {
        if($TPM.ManufacturerVersionFull20) {
            if ([Version]$TPM.ManufacturerVersionFull20 -ge $ExpectedTPMVersion) {
                $retVal = $true
            }
        }
    }
    return $retVal
}
catch {
    throw $_
}