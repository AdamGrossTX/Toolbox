#Update the commandline using the docs reference here:
#https://learn.microsoft.com/en-us/mem/configmgr/core/clients/deploy/deploy-clients-cmg-azure#install-and-register-the-client-using-azure-ad-identity
#Copy ccmsetup.msi, ccmsetup.exe & cmtrace.exe down with the script

Start-Transcript -Path "C:\Windows\Temp\CcmSetup.msi.ps1.log" -Force -ErrorAction SilentlyContinue
try {
    Write-Host (Get-Date)

    $TempFolder = "C:\Windows\Temp\CCMsetup"

    if (!(Test-Path $TempFolder)) {
        New-Item -ItemType Directory -Path $TempFolder
    }
    
    Copy-Item .\ccmsetup.exe $TempFolder -Force -ErrorAction SilentlyContinue
    Copy-Item .\ccmsetup.msi $TempFolder -Force -ErrorAction SilentlyContinue
    Copy-Item .\cmtrace.exe $TempFolder -Force -ErrorAction SilentlyContinue

    Start-Process msiexec -Wait -ArgumentList '/i ccmsetup.msi /q CCMSETUPCMD="/usepkicert /mp:<YOURCMGURL> CCMHOSTNAME=<YOURCMGHOSTNAME> SMSSiteCode=CRT AADRESOURCEURI=<YOURAADResourceID> AADTENANTID=<YOURTENANTID> AADCLIENTAPPID=<YOURAPPID> MANAGEDINSTALLER=1"' -Verbose

    do { 
        Write-Host "Waiting for ccmsetup to complete."
        Start-Sleep -Seconds 30
    } while ((Get-Process -Name ccmsetup -ErrorAction SilentlyContinue) -ne $null)

    Write-Host (Get-Date)
    Start-Sleep -Seconds 10
    
    [string[]]$string = @("CcmSetup is exiting with return code ","CcmSetup failed with error code ")
    $exitlog = get-content "C:\Windows\ccmsetup\Logs\ccmsetup.log" | select-string $string
    $split = (($exitlog -split "]").Item(0)).split(" ")
    $ccmsetup_exitcode = $split.item(($split.Count) - 1)

    $ExistingTask = Get-ScheduledTask -TaskName "Configuration Manager Client Retry Task" -ErrorAction SilentlyContinue
    if ($ExistingTask) {
        $ExistingTriggers = $ExistingTask.Triggers
        if (-not ($ExistingTriggers.CimClass.CimClassName -eq 'MSFT_TaskLogonTrigger')) {
            $ExistingTask.Triggers += New-ScheduledTaskTrigger -AtLogOn
            $ExistingTask | Set-ScheduledTask
        }
        else {
            Write-Host "Trigger Already Exists"
        }
    }
    else {
        Write-Host "No Scheduled Task Found"
    }

    Write-Host (Get-Date)
    if ($ccmsetup_exitcode -in (0, 7)) {
        Write-Host "Client Installed"
    }
    else {
        Write-Error $ccmsetup_exitcode
    }
    return $ccmsetup_exitcode

}
catch {
    throw $_
}

Stop-Transcript -ErrorAction SilentlyContinue
