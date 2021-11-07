<#
.SYNOPSIS
   WMI Class Creation and Population Script
.DESCRIPTION
   Use to create a custom WMI Class from a list of registry keys
.PARAMETER NameSpace
    WMI Namespace where new class will be created
.PARAMETER ClassName
    New WMI class name. Be sure to use a unique class since an existing class will be overwitten.
.PARAMETER ClassPropertyList
    An array of value names to be used as class properties.
.PARAMETER RegistryKeyList
    A list of registry key paths that will be collected to be stored into a new instance of the class.
.NOTES
  Version:        1.0
  Author:         Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:  08/09/2019
  Purpose/Change: Initial script development
  
.EXAMPLE
    Custom-WMIClass -NameSpace "root\cimv2" -ClassName "CM_SetupDiag" -ClassPropertyList @( "FailureData","FailureDetails","HostOSVersion","LastSetupOperation","LastSetupPhase","ProfileGuid","ProfileName","Remediation","RollbackElapsedTime","RollbackEndTime","RollbackStartTime","SetupDiagVersion","TargetOSVersion","UpgradeElapsedTime","UpgradeEndTime","UpgradeStartTime","UpgradeStartTime","DeviceDescription","HardwareId","InfName","DriverVersion","RecoveryStartTime","InstallAttempts") -RegistryKeyList @("HKLM:System\Setup\MoSetup\Tracking","HKLM:System\Setup\MoSetup\Volatile\SetupDiag")
#>

Param (
    $IncomingValue,
    [string]$NameSpace = "root\cimv2",
    [string]$ClassName = "CM_InstalledSoftware_ByUser",
    [switch]$Remediate=$false,
    [hashtable]$ClassPropertyList = @{
        "KeyName" = @{
            "type" = [System.Management.CimType]::String
            "qualifiers" = @('key','read')
        }
        "SID" = @{
            "type" = [System.Management.CimType]::String
            "qualifiers" = @('key','read')
        }
        "UserName" = @{
            "type" = [System.Management.CimType]::String
            "qualifiers" = @('key','read')
        }
        'DisplayIcon' = @{
            "type" = [System.Management.CimType]::String
            "qualifiers" = @('read')
        }
        'DisplayName' = @{
            "type" = [System.Management.CimType]::String
            "qualifiers" = @('read')
        }
        'DisplayVersion' = @{
            "type" = [System.Management.CimType]::String
            "qualifiers" = @('read')
        }
        'EstimatedSize' = @{
            "type" = [System.Management.CimType]::UInt32
            "qualifiers" = @('read')
        }
        'HelpLink' = @{
            "type" = [System.Management.CimType]::String
            "qualifiers" = @('read')
        }
        'InstallDate' = @{
            "type" = [System.Management.CimType]::String
            "qualifiers" = @('read')
        }
        'InstallLocation' = @{
            "type" = [System.Management.CimType]::String
            "qualifiers" = @('read')
        }
        'Language' = @{
            "type" = [System.Management.CimType]::UInt32
            "qualifiers" = @('read')
        }
        'NoModify' = @{
            "type" = [System.Management.CimType]::UInt32
            "qualifiers" = @('read')
        }
        'NoRepair' = @{
            "type" = [System.Management.CimType]::UInt32
            "qualifiers" = @('read')
        }
        'Publisher' = @{
            "type" = [System.Management.CimType]::String
            "qualifiers" = @('read')
        }
        'QuietUninstallString' = @{
            "type" = [System.Management.CimType]::String
            "qualifiers" = @('read')
        }
        'UninstallString' = @{
            "type" = [System.Management.CimType]::String
            "qualifiers" = @('read')
        }
        'URLUpdateInfo' = @{
            "type" = [System.Management.CimType]::String
            "qualifiers" = @('read')
        }
        "RegistryKey" = @{
            "type" = [System.Management.CimType]::String
            "qualifiers" = @('read')
        }
    }
)

$main = {
    Try {
        $NewClass = New-CustWMIClass -NameSpace $NameSpace -Class $ClassName -PropertyList $ClassPropertyList -RemoveExisting
        $UserList = Get-UserList

        $AppList = @()
        ForEach ($User in $UserList) { 
            $AppList += Get-UserUninstallKeys -User $User
        }
        If($Remediate) {
            #ForEach ($UserObj in $UserListToProcess) {
                #Update-CachedModeSettings -CurrentSettings $UserObj -DesiredSettings $Settings.$DesiredSetting
            #}
            #$UserListToProcess = Get-UserList -UserName $UserName -LookupList $CachedModeKeys -SettingsList $Settings -MainKey $CachedModeKeys[0]
        }
        $Count = 0
        ForEach ($App in $AppList) {
            $Count++
            Set-CustWMIClass -NameSpace $NameSpace -Class $ClassName -Values $App -PropertyList $ClassPropertyList -ProfileCount $Count | Out-Null
        }

        Return $True
    }
    Catch {
        Return $Error[0]
    }
}


<#function Update-CachedModeSettings {
    Param(
        $CurrentSettings,
        $DesiredSettings
    )

    $Key = $CurrentSettings.RegistryKey
    
    If(($CurrentSettings["CachedModeSetting"] -eq "Disabled" -or $CurrentSettings["CachedModeSetting"] -eq "InvalidSettings") -and ($Key -notin ("NoneFound","ERROR","NoOutlookProfile"))) {
        ForEach($Property in $DesiredSettings.Keys) {
            $CurrentValue = (Get-ItemProperty -Path REGISTRY::$Key -Name $Property -ErrorAction SilentlyContinue).$Property
            If(!($CurrentValue) -or (!($Property -eq "00036601"))) {
                $NewValue = $DesiredSettings.$Property
            }
            Else {
                $NewValue = $CurrentValue
                for($i=0; $i -lt $CurrentValue.count ; $i++)
                {
                    $NewValue[$i] = $CurrentValue[$i] -bor $DesiredSettings.$Property[$i]
                }
            }
            New-ItemProperty -Path REGISTRY::$Key -PropertyType Binary -Name $Property -Value $NewValue -Force | Out-Null
        }
    }
}
#>
function Get-UserList {

    $HKEYUsers = Get-ChildItem -Path REGISTRY::HKU | where-object { ($_.Name -like "*S-1-5-21*") -and ($_.Name -notlike "*_Classes")}

    $UserList = @()
   
    If($HKEYUsers) {
        ForEach ($UserSIDKey in $HKEYUsers) {
            $UserProfile = Get-ChildItem REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Where-Object { $_.name -like "*" + $UserSIDKey.PSChildName + "*" }
            $User = @{}
            $User["UserName"] = (([system.security.principal.securityidentIfier]$UserProfile.PSChildName).Translate([System.Security.Principal.NTAccount])).ToString()
            $User["SID"] = $UserProfile.PSChildName
            $UserList += $User
        }
    }
<#    Else {
        $User = @{}
        $User['UserName'] = "NoUserSIDKey"
        $User['RegistryKey'] = "NoUserSIDKey"
        $User['OutlookProfileName'] = "NoUserSIDKey"
        $User['SID'] = "NoUserSIDKey"
        $User['CachedModeSetting'] = "NoUserSIDKey"
        #$User["DateCollected"] = (Get-Date -Format "MM/dd/yyyy HH:mm:ss")
        $UserList += $User
    }
#>
	Return $UserList
}

Function Get-UserUninstallKeys {
	Param
	(
        $User
    )
    
    $Key = "HKEY_USERS\" + $User["SID"] + "\Software\Microsoft\Windows\CurrentVersion\Uninstall"
    
    $ResultsList = @()
    
    Try {
        If ((Test-Path REGISTRY::$Key) -eq $true) {
            $UninstallKeys = Get-ChildItem -Path REGISTRY::$Key -recurse -ErrorAction Stop
            If($UninstallKeys) {
                ForEach($Key in $UninstallKeys) {
                    $FoundValues = @{}
                    $FoundValues["SID"] = $User["SID"]
                    $FoundValues["UserName"] = $User["UserName"]
                    If ((Test-Path REGISTRY::$Key) -eq $true) { 
                        $FoundValues["KeyName"] = $Key.PSChildName
                        $FoundValues["RegistryKey"] = $Key.Name
                        ForEach($Property in $Key.Property) {
                            $Value = (Get-ItemProperty REGISTRY::$Key).$Property
                            If($Value) {
                                $FoundValues[$Property] += $Value
                            } Else {
                                $FoundValues[$Property] = $null
                            }
                        }
                    }
                    $ResultsList += $FoundValues
                }
            }
<#            Else {
                $FoundValues = @{}
                $FoundValues["SID"] = $SID
                $FoundValues["KeyName"] = "NoneFound"
                $FoundValues["Values"] = "NoneFound"
                $FoundValues["OutlookProfileName"] = "NoneFound"
                $FoundValues["CachedModeSetting"] = "NoneFound"
                $ResultsList += $FoundValues
            }
#>
        }
<#
        Else {
            $FoundValues = @{}
            $FoundValues["SID"] = $SID
            $FoundValues["RegistryKey"] = "NoOutlookProfile"
            $FoundValues["Values"] = "NoOutlookProfile"
            $FoundValues["OutlookProfileName"] = "NoOutlookProfile"
            $FoundValues["CachedModeSetting"] = "NoOutlookProfile"
            $ResultsList += $FoundValues
        }
#>
    }
    Catch {
        Throw $Error[0]
<#        $FoundValues = @{}
        $FoundValues["SID"] = $SID
        $FoundValues["RegistryKey"] = "ERROR"
        $FoundValues["Values"] = "ERROR"
        $FoundValues["OutlookProfileName"] = "ERROR"
        $FoundValues["CachedModeSetting"] = "ERROR"
        $ResultsList += $FoundValues
#>
    }

	Return $ResultsList
}

Function Remove-CustWMIClass {
Param (
   [String]$NameSpace,
   [String]$Class
)
   Try {
      Write-Verbose "Create a new empty '$Class' to populate later" | Out-Null
      Remove-WMIObject -Namespace $NameSpace -class $Class -ErrorAction SilentlyContinue
   }
   Catch {
      Throw $Error[0]
   }
}

Function New-CustWMIClass {
    Param (
        [String]$NameSpace,
        [String]$Class,
        $PropertyList,
        [Switch]$RemoveExisting
    )
    Try {
        If($RemoveExisting.IsPresent) {
            Remove-CustWMIClass -NameSpace $NameSpace -Class $Class
        } 

        If (Get-CimClass -ClassName $Class -Namespace $NameSpace -ErrorAction SilentlyContinue) {
            Write-Verbose "WMI Class $Class Already Exists" | Out-Null
        }    
        Else {
            Write-Verbose "Create WMI Class '$Class'" | Out-Null
            $NewClass = New-Object System.Management.ManagementClass($NameSpace, [String]::Empty, $Null); 
            $NewClass['__CLASS'] = $Class
            $NewClass.Qualifiers.Add("Static", $true)
        
            ForEach($key in $PropertyList.keys) {
            $NewClass.Properties.Add("$($key)", $PropertyList["$($key)"].Type, $false)
            ForEach($Qualifier in $PropertyList[$Key].Qualifiers) {
                $NewClass.Properties[$key].Qualifiers.Add("$($Qualifier)", $true)
            }
        }
            $NewClass.Put() | Out-Null
        }
        Write-Verbose "End of trying to create an empty $Class to populate later" | Out-Null
    }
    Catch {
        Throw $Error[0]
    }
}
 
Function Set-CustWMIClass {
Param (
   [String]$NameSpace,
   [String]$Class,
   $Values,
   $PropertyList,
   $ProfileCount
)
   Try {
      $ValueList = @{} 
      ForEach ($Key in $PropertyList.Keys) {
         If($Values[$key] -ne $Null) {
            If($Values[$key] -is [int32]) {
               $ValueList[$Key] = ([uint32]$Values[$key])
            } 
            ElseIf($Values[$key] -is [int64]) {
               $ValueList[$Key] = ([uint64]$Values[$key])
            } 
            Else {
               $ValueList[$Key] = $Values[$key]
            }
         }
         If((Get-CimInstance -Namespace $NameSpace -ClassName $Class -KeyOnly)."SID" -eq $ValueList["SID"]) {
            $ValueList["SID"] = "{0} | {1}" -f $ValueList[$Key], $ProfileCount
          }
      }
      $NewInstance = New-CimInstance -Namespace $NameSpace -ClassName $Class -Arguments $ValueList -ErrorAction Continue
   }
   Catch {
      Throw $Error[0]
   }
   Return $NewInstance
}

& $Main