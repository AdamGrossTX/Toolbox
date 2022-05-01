<#
.NOTES
    Author:           Adam Gross - @AdamGrossTX
    GitHub:           https://www.github.com/AdamGrossTX
    WebSite:          https://www.asquaredozen.com

#>
[cmdletbinding()]
param(
    $IncomingValue,
    $Remediate = $False
)


$NoncompliantCount = 0

$PropertyList = @{}
$PassiveMode =
    [PSCustomObject]@{
        Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender"
        Property = "PassiveMode"
    }

try {
    $PassiveModeCurrentValue = Get-ItemPropertyValue -Path registry::"$($PassiveMode.Key)" -Name $PassiveMode.Property -ErrorAction SilentlyContinue
}
catch {
}

$PropertyList = @(
    [PSCustomObject]@{
        Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WdBoot"
        Property = "Group"
        PropertyType = "String"
        Value = "Early-Launch"
    },

    [PSCustomObject]@{
        Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WdBoot"
        Property = "Start"
        PropertyType = "DWord"
        Value = 0
    },

    [PSCustomObject]@{
        Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WdFilter"
        Property = "Start"
        PropertyType = "DWord"
        Value = 0
    },

    [PSCustomObject]@{
        Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender"
        Property = "DisableAntiSpyware"
        PropertyType = "DWord"
        Value = 0
    },

    [PSCustomObject]@{
        Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender"
        Property = "DisableAntiVirus"
        PropertyType = "DWord"
        Value = 0
    },

    [PSCustomObject]@{
        Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender"
        Property = "PassiveMode"
        PropertyType = "DWord"
        Value = if($PassiveModeCurrentValue -eq 0) { 0 } else { 2 }
    },

    [PSCustomObject]@{
        Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WinDefend"
        Property = "Start"
        PropertyType = "DWord"
        Value = 2
    }
)


foreach($PropertyItem in $PropertyList) {
    try {
        $CurrentValue = Get-ItemPropertyValue -Path registry::"$($PropertyItem.Key)" -Name $PropertyItem.Property -ErrorAction SilentlyContinue
    }
    catch {
    }

    if($CurrentValue -ne $PropertyItem.Value) {
    $NoncompliantCount++
        try {
            if($Remediate) {
                New-ItemProperty -Path registry::"$($PropertyItem.Key)"  -Name $PropertyItem.Property -PropertyType $PropertyItem.ValueType -Value $PropertyItem.Value -Force -ErrorAction Stop | Out-Null
            }
        }
        catch {
            Write-Host "Error Setting New Value"
            $PropertyItem
            $CurrentValue
        }
    }

    $CurrentValue = $null
}

return $NoncompliantCount