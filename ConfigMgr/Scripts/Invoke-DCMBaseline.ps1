#Trigger-BaselineEvaluation
<#
.SYNOPSIS
   Trigger a the evaluation of client baselines
.PARAMETER BaseLineName
    The name of the baseline to be triggered. If NO BaseLinName is specified ALL baselines are client evaluated. 
.NOTES
  Version:        1.0
  Author:         Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:  09/03/2020
  Purpose/Change: 
    1.0 Initial script development
#>

[cmdletbinding()]
Param(
    [string]$BaseLineName
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

    If ($BaselineName) {
        $Filter = "DisplayName='{0}' and PolicyType is null" -f $BaseLineName
    }
    Else {
        $Filter = "PolicyType is null"
    }
    $Baselines = Get-CIMInstance -Namespace $NameSpace -ClassName $ClassName -Filter $Filter

    If ($Baselines) {
        $Results = ForEach ($Baseline in $Baselines) {
            $ArgsList = @{
                Name = $BaseLine.Name
                Version = $Baseline.Version
                IsMachineTarget = $True
                IsEnforced = $True
            }
            $BaseLine | Invoke-CimMethod -MethodName $MethodName -Arguments $ArgsList | Out-Null
            $Filter = "DisplayName='{0}'" -f $BaseLine.DisplayName
            [int]$ComplianceStatus = (Get-CIMInstance -Namespace $NameSpace -ClassName $ClassName -Filter $Filter).LastComplianceStatus
            
            "{0} : {1}" -f $BaseLine.DisplayName, $Status[$ComplianceStatus]
        }
            Return $Results
    }
    Else {
        Return "No Baseline Found"
    }
}
Catch {
    Return $_
}