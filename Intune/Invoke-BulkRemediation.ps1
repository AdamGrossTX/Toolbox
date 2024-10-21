. .\MGGraph-Helper.ps1

Connect-MgGraph -scopes "DeviceManagementConfiguration.Read.All", "DeviceManagementManagedDevices.Read.All"

$Devices = Invoke-GraphGet -URI "https://graph.microsoft.com/beta/deviceManagement/managedDevices"

$Scripts = Invoke-GraphGet -URI "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts?`$expand=assignments,runSummary"

foreach ($script in $Scripts) {
    Write-Host "$([array]::indexof($Scripts,$Script)) : $($Script.DisplayName)"
    #$script | Select-Object @{Name="index";expression={[array]::indexof($Scripts,$Script)}},IntuneId,DisplayName, Description
}

$SelectedScriptId = Read-Host -Prompt "Enter index of the script to run"

if (-not $SelectedScriptId) {
    Write-Host "No script selected. Exiting."
}
elseif (-not $Scripts[$SelectedScriptId]) {
    Write-Host "Invalid script ID selected. Exiting."
}
else {
    $body = @{
        "scriptPolicyId" = "$($Scripts[$SelectedScriptId].id)"
    }

    foreach ($device in $Devices) {
        Write-Host "Initiating remediation package $($Scripts[$SelectedScriptId].DisplayName) for $($Device.DeviceName)" -ForegroundColor Cyan
        $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($device.id)/initiateOnDemandProactiveRemediation"
        Invoke-GraphPost -Uri $uri -Body $body
    }
}
