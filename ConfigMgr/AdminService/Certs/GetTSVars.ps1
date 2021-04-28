# https://ccmexec.com/2016/11/dump-task-sequence-variables-during-osd-the-safe-way/

#$ExcludeVariables = @('_OSDOAF','_SMSTSReserved','_SMSTSTaskSequence')

# Config End

$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
$logPath = $tsenv.Value("_SMSTSLogPath")
$now = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$logFile = "TSVariables-$now.log"
$logFileFullName = Join-Path -Path $logPath -ChildPath $logFile

function MatchArrayItem {
    param (
        [array]$Arr,
        [string]$Item
        )

    $result = ($null -ne ($Arr | ? { $Item -match $_ }))
    return $result
}

$tsenv.GetVariables() | % {
            "$_ = $($tsenv.Value($_))"
            }
    


    $tsenv.Value("_SMSTSRootCACerts")