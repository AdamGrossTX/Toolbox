param(
    [cmdletbinding()]
    [switch]$remediate = $true,
    $RuleObjects = @(

        #region Block Windows Updates
        #https://github.com/Azure/azure-support-scripts/blob/master/Windows%20Update/README.md
        @{
            name   = "NoAutoUpdate"
            action = "C"
            type   = "REG_DWORD"
            hive   = "HKEY_LOCAL_MACHINE"
            key    = "Software\Policies\Microsoft\Windows\WindowsUpdate\AU"
            value  = 1
        },
        @{
            name   = "AUOptions"
            action = "C"
            type   = "REG_DWORD"
            hive   = "HKEY_LOCAL_MACHINE"
            key    = "Software\Policies\Microsoft\Windows\WindowsUpdate\AU"
            value  = 3

        },
        @{
            name   = "SetDisableUXWUAccess"
            action = "C"
            type   = "REG_DWORD"
            hive   = "HKEY_LOCAL_MACHINE"
            key    = "Software\Policies\Microsoft\Windows\WindowsUpdate"
            value  = 1

        }

        #endregion
        #region 
        @{
            name   = "CloudKerberosTicketRetrievalEnabled"
            action = "C"
            type   = "REG_DWORD"
            hive   = "HKEY_LOCAL_MACHINE"
            key    = "SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
            value  = 1
        },
        @{
            name   = "LoadCredKeyFromProfile"
            action = "C"
            type   = "REG_DWORD"
            hive   = "HKEY_LOCAL_MACHINE"
            key    = "Software\Policies\Microsoft\AzureADAccount"
            value  = 1
        },
        #endregion
        @{
            name   = "OneDrive"
            action = "C"
            type   = "REG_SZ"
            hive   = "HKEY_LOCAL_MACHINE"
            key    = "SYSTEM\CurrentControlSet\Control\Terminal Server\RailRunonce"
            value  = '"C:\Program Files\Microsoft OneDrive\OneDrive.exe" /background'
        },
        @{
            name   = "IsWVDEnvironment"
            action = "C"
            type   = "REG_DWORD"
            hive   = "HKEY_LOCAL_MACHINE"
            key    = "SOFTWARE\Microsoft\Teams"
            value  = 1

        },
        #Disable Windows CoPilot
        @{
            name   = "TurnOffWindowsCopilot"
            action = "C"
            type   = "REG_DWORD"
            hive   = "HKEY_LOCAL_MACHINE"
            key    = "SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
            value  = 1

        }
    )
)

[hashtable]$RegistryValueKind = @{
    "REG_MULTI_SZ"  = [Microsoft.Win32.RegistryValueKind]::MultiString
    "REG_DWORD"     = [Microsoft.Win32.RegistryValueKind]::DWord
    "REG_SZ"        = [Microsoft.Win32.RegistryValueKind]::String
    "REG_QWORD"     = [Microsoft.Win32.RegistryValueKind]::QWord
    "REG_BINARY"    = [Microsoft.Win32.RegistryValueKind]::Binary
    "REG_EXPAND_SZ" = [Microsoft.Win32.RegistryValueKind]::ExpandString
}

$NeedsRemediation = $false

function Invoke-ProcessRegistryItem {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$RuleObject
    )

    try {
        [bool]$Updated = $false

        $RuleObject.Path = (Join-Path -Path "Registry::$($RuleObject.hive)" -ChildPath $RuleObject.key)
        $RuleObject.PropertyName = if ($RuleObject.default -eq 1) { "(Default)" } else { [string]$RuleObject.name }
        $RuleObject.PropertyType = $RegistryValueKind["$($RuleObject.type)"]
        $RuleObject.PropertyValue = $RuleObject.value

        $CurrentItemPath = Get-Item -Path $RuleObject.Path -ErrorAction SilentlyContinue

        #Delete item and children if Action is Replace or Delete and PropertyName/PropertyValue are not set
        if ($CurrentItemPath -and ($RuleObject.action -in ('R', 'D')) -and (-not $RuleObject.PropertyName) -and (-not $RuleObject.PropertyValue)) {
            if ($remediate.IsPresent) {
                $CurrentItemPath | Remove-Item -Force
                $CurrentItemPath = $Null
            }
            else {
                Write-Output "$($RuleObject.PropertyName) not found."
                $NeedsRemediation = $true
            }
        }

        #Create new key if Action is Create or Replace
        if (-not $CurrentItemPath -and ($RuleObject.action -in ('C', 'R', 'U'))) {
            if ($remediate.IsPresent) {
                $CurrentItemPath = New-Item -Path $RuleObject.Path -Force
                $Updated = $True
            }
            else {
                Write-Output "$($RuleObject.Path) not found."
                $NeedsRemediation = $true
            }
        }

        if ($RuleObject.PropertyName) {
            $CurrentProperty = $CurrentItemPath | Get-ItemProperty -Name $RuleObject.PropertyName -ErrorAction SilentlyContinue

            #Delete item and children if Action is Replace and PropertyValue is not set or if Action is Delete (no PropertyValue is passed for a Delete Action)
            if ($CurrentProperty -and (($RuleObject.action -in ('R')) -and (-not $RuleObject.PropertyValue)) -or ($RuleObject.action -in ('D'))) {
                if ($remediate.IsPresent) {
                    $CurrentProperty | Remove-ItemProperty -Name $RuleObject.PropertyName -Force -ErrorAction SilentlyContinue
                    $CurrentProperty = $Null
                }
                else {
                    Write-Output "$($RuleObject.PropertyName) found. Deletion Needed."
                    $NeedsRemediation = $true
                }

            }

            #Create new property if action is Create or Replace
            if (-not $CurrentProperty -and ($RuleObject.action -in ('C', 'R', 'U'))) {
                if ($remediate.IsPresent) {
                    $CurrentProperty = $CurrentItemPath | New-ItemProperty -Name $RuleObject.PropertyName -PropertyType $RuleObject.PropertyType -Force
                    $Updated = $True
                }
                else {
                    Write-Output "$($RuleObject.PropertyName) found."
                    $NeedsRemediation = $true
                }
            }
        }

        if ($RuleObject.PropertyValue -and $RuleObject.PropertyName -and ($RuleObject.action -in ('C', 'R', 'U'))) {
            $CurrentPropertyValue = $CurrentProperty | Get-ItemPropertyValue -Name $RuleObject.PropertyName -ErrorAction SilentlyContinue

            #Delete item and children if Action is Replace
            if ($CurrentPropertyValue -and ($RuleObject.action -in ('R'))) {
                if ($remediate.IsPresent) {
                    $CurrentProperty | Set-ItemProperty -Name $RuleObject.PropertyName -Value $Null
                    $CurrentProperty = $CurrentItemPath | Get-ItemProperty -Name $RuleObject.PropertyName -ErrorAction SilentlyContinue
                    $CurrentPropertyValue = $Null
                }
            }

            #Set value if action is Create Update or Replace
            if ($RuleObject.action -in ('C', 'R', 'U')) {
                if ($remediate.IsPresent) {
                    $CurrentPropertyValue = $CurrentProperty | Set-ItemProperty -Name $RuleObject.PropertyName -Value $RuleObject.PropertyValue
                    $CurrentProperty = $CurrentItemPath | Get-ItemProperty -Name $RuleObject.PropertyName -ErrorAction SilentlyContinue
                    $Updated = $True
                }
            }
        }

        $returnValue = if ($remediate.IsPresent) {
            $CurrentProperty
        }
        else {
            $NeedsRemediation
        }

        return $returnValue
    }
    catch {
        throw $_
    }
}

try {
    foreach ($RuleObject in $RuleObjects) {
        if ($remediate) {
            $return = Invoke-ProcessRegistryItem -RuleObject $RuleObject
            Write-Host "Remediated $($RuleObject.name)"
        }
        else {
            Write-Host "Checking $($RuleObject.name)"
            $NeedsRemediation = Invoke-ProcessRegistryItem -RuleObject $RuleObject
            if ($NeedsRemediation) {
                Write-Host "Remediation Needed."
                exit 1
            }
        }
    }
}
catch {
    Write-Warning $_
    exit 1
}