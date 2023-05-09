param(
    [switch]$remediate = $false
)
try {
    $UWFFeatureState = (Get-WindowsOptionalFeature -FeatureName "Client-UnifiedWriteFilter" -Online -ErrorAction SilentlyContinue).State
    if ($UWFFeatureState -eq "Disabled") {
        if ($Remediate.IsPresent) {
            $Return = Enable-WindowsOptionalFeature -Online -FeatureName "Client-UnifiedWriteFilter" -NoRestart -All -ErrorAction Continue
            Write-Host "Enabled UWF Feature"
        }
        else {
            Write-Warning "The Unified Write Filter Feature is currently disabled. Use Enable-UWFFeature to enable it before useing this module."
            exit 1
        }
    }
    else {
        Write-Host "Unified Write Filter Already Enabled."
    }
}
catch {
    throw $_
}