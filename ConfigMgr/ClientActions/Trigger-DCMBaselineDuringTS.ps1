[cmdletbinding()]
Param (
    [Switch]$ToggleProvMode = $True,
    [Switch]$TriggerSchedules,
    [string]$BitLockerPolicyName = '1. New Bitlocker',
    [int]$maxRetries = 10
)

Write-Host "Starting ConfgMgr Client Action Script"

#region Main
$Main = {

    Write-Host "Checking for ConfigMgr client install"
    Try {
        $SMSClient = GetCIMInstance -Namespace "ROOT\ccm" -ClassName "SMS_Client"
        If($SMSClient) {
            Write-Host "Client Version: $($SMSClient.ClientVersion)"
        }
        Else {
                Write-Host "Could not find ConfigMgr Client."
                Throw
        }
    }
    Catch {
        Throw $_
    }
    
    #Start-Sleep -Seconds 60

    If($ToggleProvMode.IsPresent) {
        Write-Host "Disabling Provisioning Mode"
        InvokeCIMMethod -Namespace "root\CCM" -ClassName "SMS_Client" -MethodName "SetClientProvisioningMode" -Arguments @{bEnable = $False}
        [bool]$ProvisioningModeOn = [System.Convert]::ToBoolean(((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\CCM\CcmExec" -Name "ProvisioningMode" -ErrorAction Stop).ProvisioningMode))
        If(!($ProvisioningModeOn)) {
            Write-Host "Provisioning Mode Disabled."
        }
        Else {
            Write-Host "Failed to disable provisioning mode."
        }
    }


    GetCIMInstance -Namespace "ROOT\ccm\Policy\Machine\ActualConfig" -ClassName "CCM_Scheduler_ScheduledMessage" -timeout 10 -MaxRetries $maxRetries
    InvokeCIMMethod -Namespace "ROOT\ccm" -ClassName "SMS_Client" -MethodName "RequestMachinePolicy"  -timeout 30 -MaxRetries $maxRetries
    InvokeCIMMethod -Namespace "ROOT\ccm" -ClassName "SMS_Client" -MethodName "EvaluateMachinePolicy"  -timeout 30 -MaxRetries $maxRetries


    If($TriggerSchedules.IsPresent) {
        $EnabledSchedules = @()
        $EnabledSchedules += [pscustomobject]@{ ScheduleName =  'Software Update Deployment Evaluation Cycle'; ScheduleID = '{00000000-0000-0000-0000-000000000114}' }
        $EnabledSchedules += [pscustomobject]@{ ScheduleName =  'Application Deployment Evaluation Cycle'; ScheduleID = '{00000000-0000-0000-0000-000000000121}' }
        $EnabledSchedules += [pscustomobject]@{ ScheduleName =  'Request Machine Assignments'; ScheduleID = '{00000000-0000-0000-0000-000000000021}' }
        $EnabledSchedules += [pscustomobject]@{ ScheduleName =  'Hardware Inventory'; ScheduleID = '{00000000-0000-0000-0000-000000000001}' }
        $EnabledSchedules += [pscustomobject]@{ ScheduleName =  'Discovery Inventory'; ScheduleID = '{00000000-0000-0000-0000-000000000003}' }

        TriggerClientAction -EnabledSchedules $EnabledSchedules
    }


    If($BitLockerPolicyName) {
        Write-Host "Attempting to Trigger DCM $($BitLockerPolicyName)"
        Do{
            $Result = TriggerBaselineEvaluation -BaseLineName $BitLockerPolicyName
            If(!($Result)) {
                Write-Host "Baseline not found. Sleeping 30 seconds."
                Start-Sleep -seconds 30
            }
        } Until ($Result)
    }

    Try {
        If($ToggleProvMode.IsPresent) {
            Write-Host "Checking for ConfigMgr client install"
            InvokeCIMMethod -Namespace "root\CCM" -ClassName "SMS_Client" -MethodName "SetClientProvisioningMode" -Arguments @{bEnable = $True}
            [bool]$ProvisioningModeOn = [System.Convert]::ToBoolean(((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\CCM\CcmExec" -Name "ProvisioningMode" -ErrorAction Stop).ProvisioningMode))
            If($ProvisioningModeOn) {
                Write-Host "Provisioning Mode Re-Enabled."
            }
            Else {
                Write-Host "Failed to disable provisioning mode."
            }
        }
    }
    Catch {
        Throw $_
    }
}

#endregion

#region Functions

Function InvokeCIMMethod {
    [cmdletbinding()]
    Param(
        [int]$Timeout,
        [int]$maxRetries,
        [string]$Namespace,
        [string]$ClassName,
        [string]$MethodName,
        $Arguments
    )

    $count = 0
    Try {
        Write-Host "Checking for $($ClassName)"
        Do {
            $count++
            $result =  Invoke-CimMethod -Namespace $Namespace -ClassName $ClassName -MethodName $MethodName -Arguments $Arguments -ErrorAction SilentlyContinue
            If(!($result) -and $Timeout) {
                Write-Host "Class not found. Sleeping $($Timeout) seconds."
                Start-Sleep -seconds $Timeout
            }
        } Until ($ActualConfig -or ($count -ge $maxRetries))
        
        If($result) {
            Write-Host "Executed $($MethodName)."
            Return $result
        }
        Else {
            Write-Host "Failed to execute $($MethodName)."
        }
    }
    Catch {
        Throw $_
    }
}

Function GetCIMInstance {
    [cmdletbinding()]
    Param(
        [int]$timeout,
        [int]$maxRetries,
        [string]$Namespace,
        [string]$ClassName,
        [string]$MethodName
    )

    $count = 0
    Try {
        Write-Host "Checking for $($ClassName)"
        Do {
            $count++
            $obj = Get-CimInstance -Namespace $NameSpace -ClassName $ClassName -ErrorAction SilentlyContinue
            If(!($obj) -and $Timeout) {
                Write-Host "Class not found. Sleeping $($Timeout) seconds."
                Start-Sleep -seconds $Timeout
            }
        } Until ($ActualConfig -or ($count -ge $maxRetries))
        
        If($obj) {
            Write-Host "$($ClassName) found."
            Return $Obj
        }
        Else {
            Write-Host "Could not find class $($ClassName)."
        }
    }
    Catch {
        Throw $_
    }
}

Function TriggerClientAction {
    [cmdletbinding()]
    Param (
        $EnabledSchedules
    )
    Try {
        ForEach ($Schedule in $EnabledSchedules) {
            $Done = $false
            Do {
                Write-Host "Attempting to Trigger Schedule $($Schedule.ScheduleName)"
                $ScheduleObject = Get-WmiObject -Namespace "root\ccm\Scheduler" -Class "CCM_Scheduler_History" -Filter "ScheduleID = '$($Schedule.ScheduleID)'" -ErrorAction SilentlyContinue
                If($ScheduleObject.ScheduleID -eq $Schedule.ScheduleID) {
                    $result = InvokeCIMMethod -Namespace "ROOT\ccm" -ClassName "SMS_Client" -MethodName "TriggerSchedule" -Arguments @{sScheduleID = $Schedule.ScheduleID}
                    If($result) {
                        $Done = $true
                    }
                }
                Else {
                    Write-Host "Schedule not found. Sleeping for 10 seconds."
                    Start-Sleep -seconds 10
                }
            } Until ($Done -eq $True)
            Write-Host "Successfully Triggered schedule $($Schedule.ScheduleID)."
        }
    }
    Catch {
        Throw $_
    }
}

Function TriggerBaselineEvaluation {
    [cmdletbinding()]
    Param(
        $BaseLineName
    )
    $NameSpace = "root\ccm\dcm"
    $ClassName = "SMS_DesiredConfiguration"
    $MethodName = "TriggerEvaluation"
    $Status = @{
        0 = "NonCompliant"
        1 = "Compliant"
        2 = "NotApplicable"
        3 = "Unknown"
        4 = "Error"
        5 = "NotEvaluated"
    }

    Try {

        $Filter = "DisplayName='{0}'" -f $BaseLineName
        $Baselines = Get-CIMInstance -Namespace $NameSpace -ClassName $ClassName -Filter $Filter

        If ($Baselines) {
            $Result = @()
            ForEach ($Baseline in $Baselines) {
                $ArgList = @{
                    Name = $BaseLine.Name
                    Version = $Baseline.Version
                    IsMachineTarget = $True
                    IsEnforced = $True
                }
                Invoke-CimMethod -Namespace $NameSpace -MethodName $MethodName -ClassName $ClassName -Arguments $ArgList

                $Filter = "DisplayName='{0}'" -f $BaseLine.DisplayName
                [int]$ComplianceStatus = (Get-CIMInstance -Namespace $NameSpace -ClassName $ClassName -Filter $Filter).LastComplianceStatus
                $Result += "{0} : {1}" -f $BaseLine.DisplayName, $Status[$ComplianceStatus]
            }
            Return $Result
        }
    }
    Catch {
        Throw $_
    }
}

#endregion

#region Launch Main
& $Main
#endregion