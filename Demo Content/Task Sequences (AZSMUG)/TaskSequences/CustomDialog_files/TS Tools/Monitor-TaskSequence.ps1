#https://foxdeploy.com/2016/12/16/registering-for-wmi-events-in-powershell/
#http://wragg.io/watch-for-changes-with-powershell/
#https://github.com/markwragg/PowerShell-Watch/blob/master/Watch/Public/Watch-Command.ps1
#https://stackoverflow.com/questions/10969671/using-register-wmievent-to-notify-when-a-script-starts-executing
#https://gist.github.com/keithga/bb0df90123ce61b351f0321345765cb6
#https://msdn.microsoft.com/en-us/library/cc145940.aspx
#https://slightlyovercomplicated.com/2017/03/20/how-to-control-progress-bar-in-mdtsccm-task-sequence-using-vbscript/
#https://learn-powershell.net/2013/08/02/powershell-and-events-wmi-temporary-event-subscriptions/


######################

<#


.SYNOPSIS –a brief explanation of what the script or function does.
.DESCRIPTION – a more detailed explanation of what the script or function does.
.PARAMETER name – an explanation of a specific parameter. Replace name with the parameter name. You can have one of these sections for each parameter the script or function uses.
.EXAMPLE – an example of how to use the script or function. You can have multiple .EXAMPLE sections if you want to provide more than one example.
.NOTES – any miscellaneous notes on using the script or function.
.LINK – a cross-reference to another help topic; you can have more than one of these. If you include a URL beginning with http:// or https://, the shell will open that URL when the Help command’s –online parameter is used.


    .SYNOPSIS
        Monitors WMI for an instance of CCM_TSExecutionRequest to be created then launches a specified script.

    .DESCRIPTION
        This script must be run as Local System and can be installed as a Service or launched on client startup.
        
        
        Author:  Adam Gross
        Twitter: @AdamGrossTX
        GitHub:  AdamGrossTX 

    .SYNTAX
        Monitor-TaskSequece [-Script <string>] [-ScriptArgs <string>] [<CommonParameters>]

    .PARAMETERS
        -ScriptName
            Specifies the Name of the to the script be launched when the WMI event is detected.

        -ScriptPath
            Optional Parameter with full path to script to be launched. If omitted, default is $PSSCriptRoot.
        
        -ScriptArgs
            Specifies any script arguments to pass to the script being launched.

    .LINK
        https://github.com/AdamGrossTX/PowershellScripts

    .HISTORY
        0.1 - Alpha Release

    .TODO
        -Add Logging
        -Add Service mode option
        -Add Logic to detect failed TS/Hung job
     
#>

#####################
Param
(
    
    [Parameter(HelpMessage="Specifies the Name of the to the script be launched when the WMI event is detected.")]
    [string]$ScriptName = "Process-TaskSequence.ps1",
    
    #[Parameter(HelpMessage="Optional Parameter with full path to script to be launched. If omitted, default is PSSCriptRoot.")]
    #[string]$ScriptPath = $PSScriptRoot,

    [Parameter(HelpMessage="Specifies any script arguments to pass to the script being launched.")]
    [string]$ScriptArgs,
    
    [Parameter(HelpMessage="Specifies the number of seconds between WMI polling events. Default is 30")]
    [int]$EventTimer = 30,

    [Parameter(HelpMessage="Turns script logging on or off")]
    [Switch]$EnableLog
)

[string]$ScriptPath = $PSScriptRoot


################## Clear Existing Jobs and Events ##################
#Needs some work. Really here for Dev/Debug purposes. Shouldn't be needed in prod
    #Get-Process -Name TsProgressUI -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Get-EventSubscriber | Unregister-Event
    Get-Job | Stop-Job -ErrorAction SilentlyContinue
    Get-Job | Remove-Job -ErrorAction SilentlyContinue
    $Error.Clear()
################## Functions ##################
Function Remove-ExistingJobs ($SourceIdentifier)
{
    Get-EventSubscriber -SourceIdentifier $SourceIdentifier | Unregister-Event
    Get-Job $SourceIdentifier | Stop-Job -ErrorAction SilentlyContinue
    Get-Job $SourceIdentifier | Remove-Job -ErrorAction SilentlyContinue
}

################## Additional Variables ##################

#FileWatcher Event Vars
$SCCMLogPath = "$($Env:WinDir)\CCM\Logs"
$LogFileToMonitor = "smsts.log"

#WMI Event Vars
$WMINameSpace = "Root\CCM\SoftMgmtAgent"
$WMIQuery = "Select * from __instancecreationevent within $EventTimer where targetinstance isa 'CCM_TSExecutionRequest'"
$WMISourceIdentifier = "CCM_TSExecutionRequest"
$WMIEventAction = {
    Write-Host "WMI Event Detected"
    #region Filesystem Watcher
    $fileWatcher = New-Object System.IO.FileSystemWatcher
    $fileWatcher.Path = $SCCMLogPath
    $fileWatcher.Filter = $LogFileToMonitor
    $fileWatcher.IncludeSubdirectories = $true
    $fileWatcherSourceIdentifier = "FileCreated"
    $fileWatcherAction = {
        try{
            start-process powershell -WindowStyle Hidden "$($ScriptPath)\$($ScriptName)"
        }
        Catch {
            $Error
            Get-EventSubscriber -SourceIdentifier $fileWatcherSourceIdentifier | Unregister-Event
            Get-Job -Name $fileWatcherSourceIdentifier | Stop-Job -ErrorAction SilentlyContinue
            Get-Job -Name $fileWatcherSourceIdentifier | Remove-Job -ErrorAction SilentlyContinue
            Break
        }
    }

    #Main WMI Event Action
    try{
        Write-Debug "Registering FileWatcher"
        Register-ObjectEvent -InputObject $fileWatcher -EventName Created -SourceIdentifier $fileWatcherSourceIdentifier -Action $fileWatcherAction -MessageData $fileWatcherSourceIdentifier
    }
    Catch {
        $Error
        #Get-EventSubscriber -SourceIdentifier $WMISourceIdentifier | Unregister-Event
        #Get-Job -Name $WMISourceIdentifier | Stop-Job -ErrorAction SilentlyContinue
        #Get-Job -Name $WMISourceIdentifier | Remove-Job -ErrorAction SilentlyContinue
        #Break
    }
}

################## MAIN ##################

Try {
    Write-Debug "Registering WMIEvent"
    Register-WMIEvent -Namespace $WMINameSpace -Query $WMIQuery -SourceIdentifier $WMISourceIdentifier -Action $WMIEventAction -MessageData $WMISourceIdentifier
}
Catch
{
    $Error
    #Remove-ExistingJobs $WMISourceIdentifier
    #Remove-ExistingJobs $WMISourceIdentifier

    Break
}
#Finally
#{
    #Add Logging Here
    #Remove-Variable * -ErrorAction SilentlyContinue

#}

#$query = 'Select * From __InstanceCreationEvent Within 2 Where TargetInstance Isa "Win32_Process" And TargetInstance.Name = "TsProgressUI.exe"'
#Register-WMIEvent -Query $query -SourceIdentifier Win32_Process -Action $Win32_ProcessAction

#Get-Item -Path "HKLM:SOFTWARE\Microsoft\SMS\Task Sequence"
