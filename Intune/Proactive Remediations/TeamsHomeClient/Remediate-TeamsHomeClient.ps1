param (
    [switch]$remediate = $True
)

try {
    # check if the teams app is installed
    if ($null -eq (Get-AppxPackage -Name MicrosoftTeams) ) { $AppCompliance = $true }
    else { $AppCompliance = $false }
    
    # evaluate the compliance
    if ($AppCompliance -eq $true) {

        Write-Host "Success, no app detected"
        exit 0
    }
    else {
        if($Remediate.IsPresent) {
            Get-AppxPackage -Name MicrosoftTeams | Remove-AppxPackage -ErrorAction stop
            Write-Host "Success, regkey set and app uninstalled"
            exit 0
        }
        else {
            Write-Host "Failure, app detected"
            exit 1
        }
    }
}
catch {
    $errMsg = _.Exception.Message
    Write-Host $errMsg
    exit 1
}