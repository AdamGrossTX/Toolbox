
Do {
    $GotObj = Get-CimInstance -Namespace "ROOT\ccm\Policy\Machine\ActualConfig" -ClassName "CCM_Scheduler_ScheduledMessage" -ErrorAction SilentlyContinue
    Start-Sleep -seconds 10
    Write-Host "Retrying"
} Until ($GotObj)

$GotObj

try {
    $Triggered = Invoke-WmiMethod -Namespace root\CCM -Class SMS_Client -Name RequestMachinePolicy -ErrorAction Stop
}
catch{
    Write-Host "Trigger Failed for $($Schedule.ScheduleID) with Error $($Error[0].Exception)."
    Start-Sleep -seconds 30
    break;
}

try {
    $Triggered = Invoke-WmiMethod -Namespace root\CCM -Class SMS_Client -Name EvaluateMachinePolicy -ErrorAction Stop
}
catch{
    Write-Host "Trigger Failed for $($Schedule.ScheduleID) with Error $($Error[0].Exception)."
    Start-Sleep -seconds 30
    break;
}


$EnabledSchedules = @()
$EnabledSchedules += [pscustomobject]@{ ScheduleName =  'Software Update Deployment Evaluation Cycle'; ScheduleID = '{00000000-0000-0000-0000-000000000114}' }
$EnabledSchedules += [pscustomobject]@{ ScheduleName =  'Application Deployment Evaluation Cycle'; ScheduleID = '{00000000-0000-0000-0000-000000000121}' }
$EnabledSchedules += [pscustomobject]@{ ScheduleName =  'Request Machine Assignments'; ScheduleID = '{00000000-0000-0000-0000-000000000021}' }
$EnabledSchedules += [pscustomobject]@{ ScheduleName =  'Hardware Inventory'; ScheduleID = '{00000000-0000-0000-0000-000000000001}' }
$EnabledSchedules += [pscustomobject]@{ ScheduleName =  'Discovery Inventory'; ScheduleID = '{00000000-0000-0000-0000-000000000003}' }

Try {
ForEach($Schedule in $EnabledSchedules) {
        $Done = $false
        Do {
            Write-Host "Attempting to Trigger Schedule $($Schedule.ScheduleName)"
            $SheduleObject = Get-WmiObject -Namespace "root\ccm\Scheduler" -Class "CCM_Scheduler_History" -Filter "ScheduleID = '$($Schedule.ScheduleID)'" -ErrorAction SilentlyContinue
            $SheduleObject
            If($SheduleObject.ScheduleID -eq $Schedule.ScheduleID)
            {
                $SheduleObject | Select-Object ActivationMessageSent,ActivationMessageSentIsGMT,ExpirationMessageSent,ExpirationMessageSentIsGMT,FirstEvalTime,LastTriggerTime,ScheduleID,TriggerState,UserSID
                try {
                    Invoke-WmiMethod -Namespace root\CCM -Class SMS_Client -Name TriggerSchedule $Schedule.ScheduleID -ErrorAction Stop
                    $Done = $true
                }
                catch{
                    Write-Host "Trigger Failed for $($Schedule.ScheduleID) with Error $($Error[0].Exception)."
                }
            }
            else
            {
                Write-Host "Schedule not found. Sleeping for 10 seconds."
                Start-Sleep -seconds 10
            }

        } Until ($Done -eq $True)
        Write-Host "Successfully Triggered schedule $($Schedule.ScheduleID)."
    }
}
catch{
    Write-Host "Failed."
}