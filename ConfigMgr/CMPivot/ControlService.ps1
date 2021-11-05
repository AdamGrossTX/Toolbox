[cmdletbinding()]
param (
    [Parameter(Mandatory)]
    [string]$ServiceName,
    
    [Parameter(Mandatory)]
    [ValidateSet("Start","Stop","Restart","Disable","Enable")]
    [string]$Action
)
try {
    $Service = Get-Service $ServiceName -ErrorAction Stop

    if($Service) {
        switch($Action) {
            "Start" {$Service | Start-Service -Force -PassThru}
            "Stop" {$Service | Stop-Service -Force -PassThru}
            "Restart" {$Service | Restart-Service -Force -PassThru}
            "Disable" {$Service | Set-Service -StartupType Disabled -PassThru | Stop-Service -PassThru}
            "Enable" {$Service | Set-Service -StartupType Enabled -PassThru | Start-Service -PassThru}
        }
    }
    else {
        Return "Service $($ServiceName) not found."
    }
}
catch {
    Throw $_
}