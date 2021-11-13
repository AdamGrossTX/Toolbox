<#
.NOTES
    Author:           Adam Gross - @AdamGrossTX
    GitHub:           https://www.github.com/AdamGrossTX
    WebSite:          https://www.asquaredozen.com

#>
#https://docs.microsoft.com/en-us/windows/win32/power/power-policy-settings

[cmdletbinding()]
param (
    [switch]$Remediate = $false,
    $PlanToActivate = "Balanced",
    $PlansToChange = ("Power Plan","High performance","Task Sequence High Performance","Power Saver","Task Sequence High Performance","Ultimate Performance")
)

$DefaultPlans = @{
    "Power saver"   = [PSCustomObject]@{
        ElementName = "Power saver"
        InstanceID  = "Microsoft:PowerPlan\{a1841308-3541-4fab-bc81-f71556f20b4a}"
        GUID        = "a1841308-3541-4fab-bc81-f71556f20b4a"
    }

    "Balanced"      = [PSCustomObject]@{
        ElementName = "Balanced"
        InstanceID  = "Microsoft:PowerPlan\{381b4222-f694-41f0-9685-ff5bb260df2e}"
        GUID        = "381b4222-f694-41f0-9685-ff5bb260df2e"
    }

    "High performance"  = [PSCustomObject]@{
        ElementName = "High performance"
        InstanceID  = "Microsoft:PowerPlan\{8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c}"
        GUID        = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    }
}

$NameSpace  = "ROOT\cimv2\power"
$ClassName  = "Win32_PowerPlan"

try {
    $ActivePlan = Get-CIMInstance -Namespace $NameSpace -ClassName $ClassName | Where-Object {$_.IsActive -eq $True} -ErrorAction SilentlyContinue
    if($ActivePlan -and $ActivePlan.InstanceID -ne $DefaultPlans[$PlanToActivate].InstanceID -and ($ActivePlan.ElementName -in $PlansToChange)) {
        if($Remediate.IsPresent) {
            & powercfg.exe /s $DefaultPlans[$PlanToActivate].GUID
            $NewActivePlan = Get-CIMInstance -Namespace $NameSpace -ClassName $ClassName | Where-Object {$_.IsActive -eq $True} -ErrorAction SilentlyContinue
            & powercfg /change standby-timeout-ac 0
            & powercfg /change monitor-timeout-ac 0
            & powercfg /change hibernate-timeout-ac 0
            & powercfg -setacvalueindex 381b4222-f694-41f0-9685-ff5bb260df2e 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 0
            reg.exe add "HKLM\SYSTEM\ControlSet001\Control\Power" /v CSEnabled /t REG_DWORD /d 1 /f
            Return $NewActivePlan.ElementName
        }
        else {
            Return $ActivePlan.ElementName
        }
    }
    else {
        #Default High Perf Plan not Enabled. Nothing to do.
        return $ActivePlan.ElementName
    }
}
catch {
    throw $_
}