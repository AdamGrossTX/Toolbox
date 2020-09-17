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
    $DeviceName
)

$SiteServer = "CM01.ASD.NET"
$DeviceName="CM01"

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
    $CMPivotQuery = "OperatingSystem"
    $RunCMPivotParams = @{
        Method = "Post"
        Uri = "$($BaseUri)Device($($MachineId))/AdminService.RunCMPivot"
        Body = @{"InputQuery"="$($CMPivotQuery)"} | ConvertTo-Json
        ContentType = "application/json"
        UseDefaultCredentials = $true
    }

    $RunCMPivotPivotResult = Invoke-RestMethod @RunCMPivotParams
    $OperationID = $RunCMPivotPivotResult.Value.OperationId
    Write-Host "OperationID: $($OperationID)"

    $CMPivotResultParams = @{
        Method = "Get"
        Uri = "$($BaseUri)Device($($MachineId))/AdminService.CMPivotResult(OperationId=$($OperationID))"
        ContentType = "application/json"
        UseDefaultCredentials = $true
    }

    [bool]$ResultsFound = $False
    Do {
        Try {
            $CMPivotResult = Invoke-RestMethod @CMPivotResultParams -ErrorAction Stop
            If($CMPivotResult) {
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

    $CMPivotResult.value.Result
    $CMPivotResult.value.Result | Out-GridView
}
Else {
    Write-Host "Device $($DeviceName) not found."
}