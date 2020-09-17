<#
    www.github.com/AdamGrossTX
    twitter.com/AdamGrossTX
    asquaredozen.com
    note: this script could be optimized but is broken up to make it easy to read and step through for learning how AdminService works.
#>
[cmdletbinding()]
Param (
    [string]
    $SiteServer,
    
    [string]
    $DeviceName,

    [string]
    $ScriptName
)

$SiteServer = "CM01.ASD.NET"
$DeviceName ="CM01"
$ScriptName = "WinRM"

$BaseUri = "https://$($SiteServer)/AdminService/v1.0/"
Write-Host $BaseUri

$ClassName = "Device"
$GetDeviceParams = @{
    Method = "Get"
    Uri = "$($BaseUri)$($ClassName)?`$filter=Name eq `'$($DeviceName)`'"
    ContentType = "application/json"
    UseDefaultCredentials = $true
}

$Device = Invoke-RestMethod @GetDeviceParams
$MachineId = $Device.Value.MachineId

If($MachineId) {
    $ClassName = "Script"
    $RunCMPivotParams = @{
        Method = "Get"
        Uri = "$($BaseUri)/$($ClassName)?`$filter=ScriptName eq `'$($ScriptName)`'"
        ContentType = "application/json"
        UseDefaultCredentials = $true
    }
    $ScriptObjectResult = Invoke-RestMethod @RunCMPivotParams
    $Script = $ScriptObjectResult.Value

    If($Script) {
        $RunScriptParams = @{
            Method = "Post"
            Uri = "$($BaseUri)/Device($($MachineId))/AdminService.RunScript"
            Body = @{"ScriptGuid"="$($Script.ScriptGuid)"} | ConvertTo-Json
            ContentType = "application/json"
            UseDefaultCredentials = $true
        }

        $RunScriptResult = Invoke-RestMethod @RunScriptParams
        $OperationID = $RunScriptResult.Value

        $ScriptResultParams = @{
            Method = "Get"
            Uri = "$($BaseUri)/Device($($MachineId))/AdminService.ScriptResult(OperationId=$($OperationID))"
            ContentType = "application/json"
            UseDefaultCredentials = $true
        }

        [bool]$ResultsFound = $False
        Do {
            Try {
                $ScriptResult = Invoke-RestMethod @ScriptResultParams -ErrorAction Stop
                If($ScriptResult) {
                    [bool]$ResultsFound = $True
                }
            }
            Catch {
                If("Response status code does not indicate success: 404 (Not Found).") {
                    Start-Sleep -seconds 10
                    Write-host "No results found. Waiting 10 seconds."
                    Continue
                }
                Else {
                    Throw $_
                }
            }
        } Until ($ResultsFound)

        Write-Host "ScriptStatus: $($ScriptResult.Value.Status)"
        $ScriptResult.value.Result.ScriptOutput
        $ScriptResult.value.Result.ScriptOutput | Out-GridView

    }
    Else {
        Write-Host "No Script Named $($ScriptName) Found."
    }
}
Else {
    Write-Host "Device $($DeviceName) not found."
}
