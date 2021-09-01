[cmdletbinding()]
param (
    [string]$ScheduledTaskName = "Restart GlobalProtect After Autopilot",
    [string]$FilePath = "C:\Windows\Temp\Fix-PANGPS.ps1"
)

    Start-Transcript -Path "C:\Windows\Temp\Fix-PANGPS_Launcher.log" -Force -Append -ErrorAction SilentlyContinue

try {

    Write-Output "Starting Fix-PANGPS_Launcher"

$ScriptBlock = @"
param (
    [string]`$LogFile = "C:\Program Files\Palo Alto Networks\GlobalProtect\pan_gp_event.log",
    [string]`$SearchText = "You are not authorized to connect to GlobalProtect Portal.",
    [string]`$ServiceName = "PanGPS"
)

Start-Transcript -Path "C:\Windows\Temp\Fix-PANGPS.log" -Append -Force -ErrorAction SilentlyContinue
try {
    Write-Output "Fix-PANGPS Started."
    `$Service = Get-Service -Name `$ServiceName -ErrorAction SilentlyContinue
    `$LogFileExists = Test-Path -Path `$LogFile -ErrorAction SilentlyContinue

    if(`$Service -and `$LogFileExists) {
        do {
            [string]`$LastLine = Get-Content -Path `$LogFile -Tail 1
            [bool]`$HasErrorinLog = `$LastLine -like "*`$(`$SearchText)"
            if(`$HasErrorinLog) {
                Get-Service -Name `$ServiceName -ErrorAction SilentlyContinue | Restart-Service -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 120
            }
            else {
                Write-Host "GlobalProtect appears to be functioning now."
            }
        } until(-not `$HasErrorinLog)
    }
    else {
        Write-Output "GlobalProtect service not yet installed. Or Service hasn't started. Sleeping for 2 minutes"
        Start-Sleep -Seconds 120
    }
}
catch {
    Write-Output "An error occurred attempting to restart GlobalProtect."
    throw `$_
}
finally {
    Write-Output "Fix-PANGPS completed."
}

Stop-Transcript

"@

    Write-Output "Outputting Script File."

    $ScriptBlock | Out-File -FilePath $FilePath -Force

    if (-not (Get-ScheduledTask -TaskName $ScheduledTaskName -ErrorAction SilentlyContinue)) {
        Write-Output "Creating Scheduled Task: $($ScheduledTaskName)"

        $newScheduledTaskSplat = @{
            Action      = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -windowstyle hidden -noprofile -file $($FilePath)"
            Description = 'Restart the GlobalProtect client after AutoPilot if it has not successfully connected due to no client certificate.'
            Settings    = New-ScheduledTaskSettingsSet -Compatibility Vista -AllowStartIfOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 1)
            Trigger     = New-ScheduledTaskTrigger -At ($Start = (Get-Date).AddSeconds(5)) -Once
            Principal   = New-ScheduledTaskPrincipal -UserId SYSTEM -RunLevel Highest -LogonType ServiceAccount -Id Author
        }
        $ScheduledTask = New-ScheduledTask @newScheduledTaskSplat
        $ScheduledTask.Settings.DeleteExpiredTaskAfter = "PT0S"
        $ScheduledTask.Triggers[0].StartBoundary = $Start.ToString("yyyy-MM-dd'T'HH:mm:ss")
        $ScheduledTask.Triggers[0].EndBoundary = $Start.AddMinutes(10).ToString('s')

        Register-ScheduledTask -InputObject $ScheduledTask -TaskName $ScheduledTaskName

        Write-Output "Scheduled Task Created"
    }
    else {
        Write-Output "Scheduled Task Already Exists"
    }
        Write-Output "Fix-PANGPS_Launcher completed"
        Stop-Transcript -ErrorAction SilentlyContinue
}
catch {
    Write-Output "An error has occurred"
    throw $_
}