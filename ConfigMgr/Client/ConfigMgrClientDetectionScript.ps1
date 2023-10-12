Start-Transcript c:\windows\temp\detect-configmgrclientinstalled.log -Force -ErrorAction SilentlyContinue
    
try {
    Write-Host "Sleeping 60 seconds before attempting detection to wait for client startup."
    Start-Sleep -Seconds 60
    $Installed = $false
    $SiteCode = "CRT"
    $clientVersion = (Get-CimInstance SMS_Client -Namespace root\ccm -ErrorAction SilentlyContinue).ClientVersion
    $SMSauthority = (Get-CimInstance SMS_Authority -Namespace root\ccm -ErrorAction SilentlyContinue)
    $ClientAlwaysOnInternet = Get-ItemProperty -Path registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\CCM\Security" -Name "ClientAlwaysOnInternet" -ErrorAction SilentlyContinue
    $task = try {Get-ScheduledTask -Taskname "Configuration Manager Client Retry Task" -ErrorAction SilentlyContinue} catch {}
    $taskExists = if($task) {$true} else {$false}
    $ccmsetupdl = Test-Path C:\Windows\Temp\CCMsetup\ccmsetup.exe -ErrorAction SilentlyContinue
    $ccmservice = Get-Service ccmsetup -ErrorAction SilentlyContinue
    $ccmsetupexe = Get-Process ccmsetup -ErrorAction SilentlyContinue
    if (($clientVersion -and ($SMSauthority.Name -eq "SMS:$SiteCode" -and $SMSauthority.CurrentManagementPoint)) -or ($taskExists -and $ccmsetupdl) -or $ccmservice -or $ccmsetupexe -or ($clientVersion -and $ClientAlwaysOnInternet.ClientAlwaysOnInternet -eq 1)) {
        $Installed = $true
    }

    if ($Installed) {
        Write-Host "Client Installed"
        exit 0
    }
    else {
        Write-Host "No Client | ClientVersion: $($clientVersion) | SMSauthorityName: $($SMSauthority.Name) | CurrentManagementPoint: $($SMSauthority.CurrentManagementPoint)  | TaskExists: $($taskExists)  | SetupExists: $($ccmsetupdl) | SetupServiceExists: $($ccmservice) | SetupRunning: $($ccmsetupexe) | ClientOnInternet: $($ClientAlwaysOnInternet.ClientAlwaysOnInternet)"
        exit 1
    }
}
catch {
    throw $_
}
Stop-Transcript -ErrorAction SilentlyContinue
