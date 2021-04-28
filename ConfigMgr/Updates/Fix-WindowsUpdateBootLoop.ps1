<#
.SYNOPSIS
    This script checks if there are any updates that have a pending reboot and clears the reboot flag and resets client policy.
.DESCRIPTION
    This should only be used when a device is stuck in a "boot loop" - prompts/forces a reboot, reboots, re-evaluates update deployments then prompts/reboots again for the same update.
    It is recommended to run this from ConfigMgr in the Run Scripts node.
    While it could be used as a CI, it doesn't have the logic to check for repeated reboots before remediating which could lead to other client issues if run on devices that don't have a reboot loop.

    Consider this as a Break-Fix script, not a proactive script.
.PARAMETER UpdateName
    Optional
    The full name of a specific update that needs to be checked. Update name can be found in WindowsUpdateHandler.log. Default behavior is to check all updates.

.PARAMETER Remediate
    Note this is an INT because ConfigMgr Run Scripts doesn't support Switch or Bool as parameter types. https://docs.microsoft.com/en-us/mem/configmgr/apps/deploy-use/create-deploy-scripts#limitations
    0 will only report the update status and make no changes
    1 will delete pending reboot registry keys and reset client policy

.NOTES
  Version:          1.1
  Author:           Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:    04/28/2021

  For info on configuring Run Scripts see the Microsoft ConfigMgr Docs - https://docs.microsoft.com/en-us/mem/configmgr/apps/deploy-use/create-deploy-scripts

  #Nice Blog on this concept from Paul Wetter
  https://www.wetterssource.com/featureupdatetroubleshooting


 #CMPivot Query
 #Troubleshoot Feature Update Reboot Loop - Find All Updates with CommitRequired set to 1
 #Registry('hklm:SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\CommitRequired\*') | where Value == '1'

  #>

Param (
    [Parameter()]
    [string]$UpdateName,

    [Parameter()]
    [ValidateSet(0,1)]
    [int]$Remediate #Change to 1 to remediate the issue.

)

#region variables

$CommitRequiredPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\CommitRequired"
$CommitRequired = 0

#Set UpdateName to wildcard if no update name is specified.
if([string]::IsNullOrEmpty($UpdateName)) {
    $UpdateName = "%"
}

$suFilter = "Name like '{0}'" -f $UpdateName
$usFilter = "Title like '{0}'" -f $UpdateName

#https://docs.microsoft.com/en-us/windows/deployment/update/how-windows-update-works#identifies-service-ids
#Note. Each subkey here will be a GUID that is the service that's responsible for the update/reboot.
$ParentService = @{
    "{00000000-0000-0000-0000-000000000000}" = "Unspecified / Default	WU, MU, or WSUS"
    "{9482F4B4-E343-43B6-B170-9A65BC822C77}" = "Windows Update"
    "{7971f918-a847-4430-9279-4a52d1efe18d}" = "Microsoft Update"
    "{855E8A7C-ECB4-4CA3-B045-1DFA50104289}" = "Store"
    "{8B24B027-1DEE-BABB-9A95-3517DFB9C552}" = "OS Flighting"
    "{3DA21691-E39D-4da6-8A4B-B43877BCB1B7}" = "WSUS or Configuration Manager"
}

#All possible evaluation states
$EvaluationState = @{
    0 = "ciJobStateNone"
    1 = "ciJobStateAvailable"
    2 = "ciJobStateSubmitted"
    3 = "ciJobStateDetecting"
    4 = "ciJobStatePreDownload"
    5 = "ciJobStateDownloading"
    6 = "ciJobStateWaitInstall"
    7 = "ciJobStateInstalling"
    8 = "ciJobStatePendingSoftReboot"
    9 = "ciJobStatePendingHardReboot"
    10 = "ciJobStateWaitReboot"
    11 = "ciJobStateVerifying"
    12 = "ciJobStateInstallComplete"
    13 = "ciJobStateError"
    14 = "ciJobStateWaitServiceWindow"
    15 = "ciJobStateWaitUserLogon"
    16 = "ciJobStateWaitUserLogoff"
    17 = "ciJobStateWaitJobUserLogon"
    18 = "ciJobStateWaitUserReconnect"
    19 = "ciJobStatePendingUserLogoff"
    20 = "ciJobStatePendingUpdate"
    21 = "ciJobStateWaitingRetry"
    22 = "ciJobStateWaitPresModeOff"
    23 = "ciJobStateWaitForOrchestration"
}
#endregion

#region Main
#Get update information from the ConfigMgr client.
#CCM_SoftwareUpdate lists all updates that will appear in the ConfigMgr client that haven't been installed yet.
$ConfigMgrSoftwareUpdates = Get-CimInstance -Namespace "ROOT\ccm\ClientSDK" -ClassName "CCM_SoftwareUpdate" -Filter $suFilter

#CCM_UpdateStatus lists the status of every update that has been installed by the ConfigMgr client
$AllSoftwareUpdates = Get-CimInstance -Namespace "ROOT\ccm\SoftwareUpdates\UpdatesStore" -ClassName "CCM_UpdateStatus" -Filter $usFilter

#List the evaluation state for each update. This should match what the ConfigMgr client shows in Software Center. This is only for informational purposes to validate that the stuck updates are in Software Center.
if($Remediate -ne 1) {
    if($ConfigMgrSoftwareUpdates) {
        foreach($Update in $ConfigMgrSoftwareUpdates)
        {
            if($Update.EvaluationState) {
                Write-Output "$($Update.Name) : $($EvaluationState[$Update.EvaluationState])"
            }
            else {
                Write-Output "No Evaluation State found for $($Update.Name)"
            }
        }
    }
    else {
        Write-Output "No updates found in Software Center."
    }
}

$UpdatesNeedingReboots = @()
#Check the see if the machine has a pending reboot for each update in the update store.
if($AllSoftwareUpdates) {
     foreach($Update in $AllSoftwareUpdates) {
        #checks if a reboot is required for each update in the CCM_UpdateStatus class
        $UpdateGUID = "{$($Update.UniqueId)}"
        $ServiceKeys = Get-ChildItem -Path $CommitRequiredPath -Recurse -ErrorAction SilentlyContinue | Where-Object {$_.Property -eq $UpdateGUID}
        foreach($ServiceKey in $ServiceKeys) {
            $UpdateProperty = $ServiceKey | Get-ItemProperty -Name $UpdateGUID -ErrorAction SilentlyContinue
            if($UpdateProperty.$UpdateGUID -eq 1) {
                $UpdatesNeedingReboots += [PSCustomObject]@{
                    ParentService = $ParentService.($ServiceKey.PSChildName)
                    Title = $Update.Title
                    UniqueID = $Update.UniqueID
                    UpdateGUID = $UpdateGUID
                    RegistryProperty = $UpdateProperty
                }
            }
        }
    }
}

if($Remediate -eq 1) {
    Write-Output "Resetting Updates and Client Policy"
    ForEach($Update in $UpdatesNeedingReboots) {
        $Update.RegistryProperty | Remove-ItemProperty -Name $Update.UpdateGUID -Force -ErrorAction SilentlyContinue
    }
    Invoke-WMIMethod -Namespace root\ccm -Class SMS_Client -Name ResetPolicy -ArgumentList "1"
}

if($UpdatesNeedingReboots) {
    $UpdatesNeedingReboots | Select-Object -ExcludeProperty RegistryProperty | ConvertTo-Json
} else {
    Write-Output "No Updates found in Software Update Store. Perform Software Update Evaluation Cycle."
}


#endregion
