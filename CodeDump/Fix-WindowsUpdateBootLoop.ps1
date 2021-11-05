
Param (
    [Parameter()]
    [string]
    $UpdateName = "", #put in the name of your update from WindowsUpdateHandler.log or leave blank to get all failed updates
    
    [Parameter()]
    [switch]
    $Remediate = $False #Change to true if the there is a problem detected.   
    
)

$CommitRequiredPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\CommitRequired" 
$CommitRequired = 0
$suFilter = "Name = '{0}'" -f $UpdateName
$usFilter = "Title = '{0}'" -f $UpdateName

#Get update information from the ConfigMgr client. 
#CCM_SoftwareUpdate lists all updates that will appear in the ConfigMgr client that haven't been installed yet.
$SoftwareUpdate = Get-CimInstance -Namespace "ROOT\ccm\ClientSDK" -ClassName "CCM_SoftwareUpdate" -Filter $suFilter

#CCM_UpdateStatus lists the status of every update that has been installed by the ConfigMgr client
$UpdateStatus = Get-CimInstance -Namespace "ROOT\ccm\SoftwareUpdates\UpdatesStore" -ClassName "CCM_UpdateStatus" -Filter $usFilter

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

#List the evaluation state for each update. This should match what the ConfigMgr client shows in Software Center.
If($SoftwareUpdate) {
    ForEach($Update in $SoftwareUpdate)
    {
        If($Update.EvaluationState) {
            Write-Host "$($Update.Name) : $($EvaluationState[$Update.EvaluationState])"
        }
        Else {
            Write-Host "No Evaluation State found for $($Update.Name)"
        }
        
    }
}
Else {
    Write-Host "No updates found in the ConfigMgr client"
}

#Check the see if the machine has a pending reboot for each update in the update store.
If($UpdateStatus) {
    ForEach($Update in $UpdateStatus) {

        #checks if a reboot is required for each update in the CCM_UpdateStatus class
        $Value = Get-ItemProperty -Path $CommitRequiredPath -Name "{$($Update.UniqueId)}" -ErrorAction SilentlyContinue
        $CommitRequired = Switch($Value) {
            1 {$value; Break;}
            default {0; Break;}
        }

        Write-Host "$($Update.UniqueID) : $($Update.Status) : $($CommitRequired)"
    }
}
Else {
    Write-Host "No installed updates found."
}

If($Remediate) {
    Write-Host "Resetting Updates and Client Policy"
    Remove-Item -Path $CommitRequiredPath -Recurse -Force -ErrorAction SilentlyContinue
    Invoke-WMIMethod -Namespace root\ccm -Class SMS_Client -Name ResetPolicy -ArgumentList "1"
}
