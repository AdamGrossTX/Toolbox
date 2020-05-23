<#
.SYNOPSIS
    Finds network adapters with metering enabled and disables it because metering is dumb.
.DESCRIPTION
    See SYNOPSIS
.PARAMETER $CheckOnly
    Only outputs values to the console. Doesn't make changes. Default is to fix the issues.
.PARAMETER $TakeTheSlowBoat
    This parameter does the safe and supported method of using ResetClientPolicy which wipes out exising client policies then refreshes them. 
    It takes forever to complete.
    The default will update the ActualConfig policy in WMI which is TECHNICALLY "unsupported" but totally works and is faster!
.TODO
    Add the ability to batch this with a CSV and PowerShell remoting. Maybe. Someday.
    
.NOTES
  Version:          1.0
  Author:           Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:    05/22/2020
  Purpose/Change:   Initial script development

  Reference blogs/scripts:
  https://www.powershellgallery.com/packages/NetMetered/1.0

  http://franckrichard.blogspot.com/2018/11/sccm-client-certificate-value-set-to.html
  http://franckrichard.blogspot.com/2018/11/set-onoff-metered-ethernet-connection.html
  
#>

param(
    [switch]
    $CheckOnly,

    [switch]
    $TakeTheSlowBoat
    
)

    [int]$MeteredAdapterCount = 0
    $UserCostEnum = @{
        0 = "Metering Disabled"
        2 = "Metering Enabled"
    }

    #region Data Usage Service
    $RegKey = "HKLM:\Software\Microsoft\DusmSvc\Profiles\*\`*"
    $UserCost = Get-ItemProperty -Path $RegKey -Name UserCost -ErrorAction SilentlyContinue
    ForEach($Profile in $UserCost) {
        If($Profile.UserCost -ne $null) {
            $AdapterName = (Get-NetAdapter | Where-Object {$_.InterfaceGuid -eq (Get-Item -Path $Profile.PSParentPath).PSChildName}).Name
            Write-Host "User Data Usage cost is $($UserCostEnum[$Profile.UserCost]) for adapter `"$($AdapterName)`"."
            If(!($CheckOnly.IsPresent)) {
                Write-Host "Removing UserCost registry key for adapter `"$($AdapterName)`"."
                Remove-ItemProperty -Path $Profile.PSPath -Name UserCost -Force -ErrorAction SilentlyContinue
                Restart-Service DusmSvc -Force -ErrorAction SilentlyContinue
                Get-NetAdapter -Name $AdapterName | Restart-NetAdapter
            }
            Else {
                Write-Host "No change made for adapter `"$($AdapterName)`"."
            }
            $MeteredAdapterCount++
        }
    }
    #endregion

    #region Wireless Adapters
    #Wireless adapters use netsh to change the settings.
    $ProfileList = Get-NetConnectionProfile
    ForEach ($Profile in $ProfileList.Name) {
        $Config = $null
        $Setting = $null
        $Result = $null

        $Config = (netsh wlan show profile name="$($Profile)")
        $Setting = (($Config -match "(Cost\s+:+)") -Split ":")[1] -Replace "\s"

        If ($Setting -and $Setting -ne 'Unrestricted') {
            If(!($CheckOnly.IsPresent)) {
                Write-Host "Setting $($Profile) to Unrestricted"
                $Result = (netsh wlan set profileparameter name="$Profile" cost="Unrestricted")
            }
            Else {
                Write-Host "Wireless adapter profile $($Profile) is set to $($Setting)"
            }
            $MeteredAdapterCount++
        }
    }
    #endregion

    #region ConfigMgr Client Settings
    $CCMNetworkCost = (Invoke-CimMethod -Namespace "root\ccm\ClientSDK" -ClassName "CCM_ClientUtilities" -MethodName GetNetworkCost).Value
    Write-Host "ConfigMgr Cost: $($CCMNetworkCost)"

    If($CCMNetworkCost -ne 1) {
        #Set metering to 1, restart client so it will check in, remove the policy instance, then get new policies
        $PolicyNameSpace = "root\ccm\Policy\Machine\ActualConfig"
        $NwClassName = "CCM_NetworkSettings"
        $obj = Get-CIMInstance -Namespace $PolicyNameSpace -ClassName $NwClassName
        If($obj.MeteredNetworkUsage -ne 1) {
            Write-Host "ConfigMgr MeteredNetworkUsage is set to $($obj.MeteredNetworkUsage)"

            If(!($checkOnly.IsPresent) -and !($TakeTheSlowBoat.IsPresent)) {
                Write-Host "Reseting ConfigMgr CCM_NetworkSettings Policy"
                #Set usage to 1 in the policy first. This allows the client to go get policies. 
                #We will delete the entry at the end to ensure that the setting gets re-applied after a policy refresh.
                #In testing, policies didn't reapply without removing the entry.
                $obj | Set-CimInstance -Property @{MeteredNetworkUsage=1}  
                Restart-Service -Name ccmexec -ErrorAction SilentlyContinue
                #Give policies time to churn
                Start-Sleep -Seconds 30 
                #Remove the policy entry from WMI
                $obj | Remove-CimInstance
                Invoke-CimMethod -Namespace "root\ccm" -ClassName "SMS_Client" -MethodName RequestMachinePolicy -Arguments @{uFlags = [uint32]1 }
                Invoke-CimMethod -Namespace "root\ccm" -ClassName "SMS_Client" -MethodName EvaluateMachinePolicy
            }
            ElseIf (!($checkOnly.IsPresent) -and $TakeTheSlowBoat.IsPresent) {
                Write-Host "Reseting ConfigMgr Client Polices"
                Invoke-CimMethod -Namespace "root\ccm" -ClassName "SMS_Client" -MethodName ResetPolicy -Arguments @{uFlags = [uint32]1 }
            }
            Else {
                Write-Host "No Changes were made."
            }
            $MeteredAdapterCount++
        }
    }

    Return $MeteredAdapterCount

    #region

