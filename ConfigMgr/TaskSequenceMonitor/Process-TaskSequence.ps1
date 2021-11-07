###Make sure your TS is running with the user dialog hidden


################## Setup Variables ##################
$ErrorActionPreference = "Stop";

$CustomOrgName = "A Square Dozen Testing Corp"
$ShowPSProgress = $False
$ShowTSProgress = $True
$ShoWFancyGUI = $False
$OutputErrorList = $True
$OutputActionList = $True


$Global:TSEnv = $null
$Global:TSProgressUI = $null
$Global:CurrentAction = $null
$Global:NewAction = $null
$Global:PreviousAction = $null
$Global:ActionList = @()
$Global:ErrorList = @()

$Error.Clear()
################## GetActions Script Block ##################
$GetActions = {
    try {
        If(!($TSEnv)) { #Check again here in case the TS exits by the time the script arrives here.
            $TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
        }
        Else {
            $Action = New-Object PSObject -Property @{
                SMSTSCurrentActionName = $TSEnv.Value("_SMSTSCurrentActionName")
                SMSTSLastActionRetCode = $TSEnv.Value("_SMSTSLastActionRetCode")
                SMSTSLastActionSucceeded = $TSEnv.Value("_SMSTSLastActionSucceeded")
                SMSTSNextInstructionPointer = [int]$TSEnv.Value("_SMSTSNextInstructionPointer")
                SMSTSInstructionTableSize = [int]$TSEnv.Value("_SMSTSInstructionTableSize")
                SMSTSOrgName = $TSEnv.Value("_SMSTSOrgName")
                SMSTSPackageName = $TSEnv.Value("_SMSTSPackageName")
                SMSTSCustomProgressDialogMessage = $TSEnv.Value("_SMSTSCustomProgressDialogMessage")
                CurrentActionRetCode = $null
            }
        }
    }
    Catch {
        Write-Warning "TSEnv Not Started Yet" | Out-Null
    }
    Return $Action
}

################## MAIN ##################
Try {
    Do {
        Try{
            $TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
            If($ShoWFancyGUI){start-process powershell -WindowStyle Hidden "$($PSScriptRoot)\Progress_RunSpace_Mahapps_Ring_FullScreen.ps1" -PassThru}
        }
        Catch {}
    } Until (($TSEnv))

    Try{
        Start-Process -FilePath C:\Windows\CCM\TsProgressUI.exe -ErrorAction Stop
        $TSProgressUI = new-object -comobject Microsoft.SMS.TSProgressUI -ErrorAction Stop
    }
    Catch {
        Write-Host "Failed to start TSProgressUI"
        throw $Error
    }

    Do {
        Do {
            $NewAction = Invoke-Command $GetActions

            If($CurrentAction) {
                $Diff = Compare-Object -ReferenceObject $CurrentAction -DifferenceObject $NewAction -Property "SMSTSNextInstructionPointer","SMSTSCurrentActionName" -PassThru
            } 
            Else {
                #If the TS resumes, we want to capture the existing Error and Action lists
                $ErrorList += $TsEnv.Value("TS_ErrorList")
                $ActionList += $TsEnv.Value("TS_ActionList")
                    
                If($ShowPSProgress) {Write-Progress -Activity "Task Sequence Progress" -Status "Initializing Task Sequence" -PercentComplete -1}
                If($ShowTSProgress) {$TSProgressUI.ShowTSProgress($CustomOrgName, $NewAction.SMSTSPackageName, $NewAction.SMSTSCustomProgressDialogMessage, "Step $($NewAction.SMSTSNextInstructionPointer)) of $($NewAction.SMSTSInstructionTableSize))", $NewAction.SMSTSNextInstructionPointer,  $NewAction.SMSTSInstructionTableSize)}
                $Diff = "FirstRecord"
            }
        } Until ($Diff)

        #Get the result code of the CurrentAction from the NewAction's LastActionRetCode
        If($CurrentAction){
            $CurrentAction.CurrentActionRetCode = $NewAction.SMSTSLastActionRetCode
        }
            
        #Add to the ActionList for later reporting
        $ActionList += $CurrentAction
            
        $PreviousAction = $CurrentAction
        $CurrentAction = $NewAction
        
        $StatusMessage = If($CurrentAction.SMSTSCurrentActionName){$CurrentAction.SMSTSCurrentActionName}Else{"Initializing Task Sequence"}
        If($ShowPSProgress){Write-Progress -Activity "Task Sequence Progress" -Status $StatusMessage -PercentComplete (($CurrentAction.SMSTSNextInstructionPointer / $CurrentAction.SMSTSInstructionTableSize) * 100)}
        If($ShowTSProgress) {$TSProgressUI.ShowActionProgress($CustomOrgName,$CurrentAction.SMSTSPackageName,$CurrentAction.SMSTSCustomProgressDialogMessage,$CurrentAction.SMSTSCurrentActionName,($CurrentAction.SMSTSNextInstructionPointer),$CurrentAction.SMSTSInstructionTableSize,"Step $($CurrentAction.SMSTSNextInstructionPointer) of $($CurrentAction.SMSTSInstructionTableSize)",$CurrentAction.SMSTSNextInstructionPointer,$CurrentAction.SMSTSInstructionTableSize)}
                 
                
        If($CurrentAction.SMSTSLastActionSucceeded -eq "false")
        {
            $ErrorList += $PreviousAction
        }
    }
    while (($CurrentAction.SMSTSNextInstructionPointer -ne $CurrentAction.SMSTSInstructionTableSize) -and ($TSEnv))

    If($ErrorList)
    {
        #Set the TS_ErrorList Variable to be used in the TS.
        $TsEnv.Value("TS_ErrorList")
    }
    If($ShowPSProgress) {Write-Progress -Activity "Task Sequence Progress" -Status "Finalizing Task Sequence" -PercentComplete 100 -Completed}

    If($OutputErrorList){$ErrorList | Out-GridView -Wait}
    If($OutputActionList){$ActionList | Out-GridView -Wait}
}
Catch
{
  $Error[0]
    #Throw $Error
}
#Finally
#{
    $Global:TSProgressUI = $null
    $Global:TSEnv = $null
    Get-Process -Name TsProgressUI -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "Done"
#}

Get-EventSubscriber | Unregister-Event
Get-Job | Stop-Job -ErrorAction SilentlyContinue
Get-Job | Remove-Job -ErrorAction SilentlyContinue
$Error.Clear()