[cmdletbinding()]
param(
    [switch]$AppleModelInfo = $True,
    [switch]$ConfigurationProfiles = $True,
    [switch]$EntraDevices = $True,
    [switch]$IntuneDevices = $True,
    [switch]$IntuneHardwareInfo = $True,
    [switch]$IntuneMobileApps = $True,
    #[switch]$WindowsUpdateInfo = $True,
    [switch]$IntuneAppStatusReport = $True,
    [switch]$AppGroupMembers = $True,
    [switch]$AutopilotDevices = $True,
    [switch]$IntuneDeviceCategories = $True,
    [switch]$IntuneDepOnboardingSettings = $True,
    [switch]$EntraDeviceLapsInfo,
    [switch]$IntuneAssignmentFilters = $True,
    [switch]$IntuneRoleScopeTags = $True,
    [switch]$EntraUsers = $True,
    [switch]$EntraUsersSignInLogs = $True,
    [switch]$EntraGroup = $True
)

#Install-Module dbatools -scope AllUsers
#Install-Module Microsoft.Graph -Scope AllUsers
#Import-Module dbatools
#Import-Module Microsoft.Graph

#region Functions
. .\MGGraph-Helper.ps1

function Get-ObjectPropertyInfo {
    [cmdletbinding()]
    param(
        [object]$Object
    )
    try {
        $Data = $Object.Data | Select-Object -Property *, @{Name = 'SQLLastImported'; Expression = { $Script:SQLLastImported }; }
        #$DataTable = $Data | ConvertTo-DbaDataTable
        $DataTable = $Data | Out-DataTable

        $Columns = $DataTable.Columns

        $PrimaryKey = if ($Columns.ColumnName -contains $Object.PrimaryKey) {
            $Object.PrimaryKey
        }
        elseif ($Columns.ColumnName -contains "Id") {
            "Id"
        }
        else {
            $Null
        }
        if ($Object.SkipSchemaUpdate -ne $True) {
            [Hashtable]$PropList = @{}
            foreach ($Col in $Columns) {
                $SQLType = Get-SQLType -Property $PropertyType -Length $Col.MaxLength -DataType $Col.DataType.Name
                $PropList.($Col.ColumnName) = $Col.ColumnName
            }
        }
        $ReturnVal = [pscustomobject] @{
            SkipRemoveColumns = $Object.SkipRemoveColumns
            AppendData        = $Object.AppendData
            systemName        = $Object.SystemName
            Name              = $Object.Endpoint
            TableList         = @("t_$($Object.SystemName)_$($Object.Endpoint)", "t_$($Object.SystemName)_$($Object.Endpoint)_STAGING")
            SPName            = "SP_$($Object.SystemName)_Update_$($Object.Endpoint)"
            Props             = $Columns.ColumnName
            PrimaryKey        = $PrimaryKey
            PropList          = $PropList
            Data              = $DataTable
        }
        return $ReturnVal
    }
    catch {
        $_
    }
}


function Out-DataTable {
    <#
    .SYNOPSIS
        Creates a DataTable for an object

    .DESCRIPTION
        Creates a DataTable based on an object's properties.

    .PARAMETER InputObject
        One or more objects to convert into a DataTable

    .PARAMETER NonNullable
        A list of columns to set disable AllowDBNull on

    .INPUTS
        Object
            Any object can be piped to Out-DataTable

    .OUTPUTS
    System.Data.DataTable

    .EXAMPLE
        $dt = Get-psdrive | Out-DataTable
        
        # This example creates a DataTable from the properties of Get-psdrive and assigns output to $dt variable

    .EXAMPLE
        Get-Process | Select Name, CPU | Out-DataTable | Invoke-SQLBulkCopy -ServerInstance $SQLInstance -Database $Database -Table $SQLTable -force -verbose

        # Get a list of processes and their CPU, create a datatable, bulk import that data

    .NOTES
        Adapted from script by Marc van Orsouw and function from Chad Miller
        Version History
        v1.0  - Chad Miller - Initial Release
        v1.1  - Chad Miller - Fixed Issue with Properties
        v1.2  - Chad Miller - Added setting column datatype by property as suggested by emp0
        v1.3  - Chad Miller - Corrected issue with setting datatype on empty properties
        v1.4  - Chad Miller - Corrected issue with DBNull
        v1.5  - Chad Miller - Updated example
        v1.6  - Chad Miller - Added column datatype logic with default to string
        v1.7  - Chad Miller - Fixed issue with IsArray
        v1.8  - ramblingcookiemonster - Removed if($Value) logic.  This would not catch empty strings, zero, $false and other non-null items
                                    - Added perhaps pointless error handling
        v1.9  - AdamGrossTX - Added better handling of types and field sizes to allow better SQL table sizing

    .LINK
        https://github.com/RamblingCookieMonster/PowerShell

    .LINK
        Invoke-SQLBulkCopy

    .LINK
        Invoke-Sqlcmd2

    .LINK
        New-SQLConnection

    .FUNCTIONALITY
        SQL
    #>

    [CmdletBinding()]
    [OutputType([System.Data.DataTable])]
    param(
        [Parameter( Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [PSObject[]]$InputObject
    )

    Begin {
        $dt = New-Object Data.datatable  

        function Get-ODTType {
            param($type)

            $types = @(
                'System.Boolean',
                'System.Byte[]',
                'System.Byte',
                'System.Char',
                'System.Datetime',
                'System.Decimal',
                'System.Double',
                'System.Guid',
                'System.Int16',
                'System.Int32',
                'System.Int64',
                'System.Single',
                'System.UInt16',
                'System.UInt32',
                'System.UInt64')

            if ( $types -contains $type ) {
                Write-Output "$type"
            }
            else {
                Write-Output 'System.String'
            }
        } #Get-Type
    }
    Process {
        $NullColumns = @()
        foreach ($Object in $InputObject) {
            $DR = $DT.NewRow()  
            foreach ($Property in $Object.PsObject.Properties) {
                $Name = $Property.Name
                $Value = $Property.Value
                $Type = $Property.TypeNameOfValue

                $Value = if ([string]::IsNullOrEmpty($Value)) {
                    [DBNull]::Value
                } 
                elseif ($Object.($Name).GetType().IsArray) {
                    #$DR.Item($Name) = $Value | ConvertTo-XML -As String -NoTypeInformation -Depth 1
                    $Value -join ","
                }
                elseif ($Type -eq 'System.DateTime') {
                    if ($Value -ge '1/1/1753 00:00:00') {
                        $Value
                    }
                    else {
                        [DBNull]::Value
                    }
                }
                elseif ($Type -eq 'System.Management.Automation.PSCustomObject') {
                    $Value | ConvertTo-Json -Depth 100
                }
                elseif ($Type -eq 'System.Collections.Hashtable') {
                    $Value | ConvertTo-Json -Depth 100
                }
                else {
                    $Value
                }

                #After typing, ensure that it's [DBNull]::Value 
                $Value = [string]::IsNullOrEmpty($Value) ? [DBNull]::Value : $Value
                
                if ($dt.Columns.ColumnName -notcontains $Name) {
                    $Col = New-Object Data.DataColumn
                    $Col.ColumnName = $Name
					
                    if ($Value -isnot [System.DBNull]) {
                        $Col.DataType = [System.Type]::GetType( $(Get-ODTType $property.TypeNameOfValue) )
                        if ($Col.DataType.Name -eq 'String') {
                            $Col.MaxLength = -1
                        }
                        try {
                            $DT.Columns.Add($Col)
                        }
                        catch {
                            Write-Error "Could not add column $($Col | Out-String) for property '$Name' with value '$Value' and type '$($Value.GetType().FullName)':`n$_"
                        }
                        $DR.Item($Name) = $Value
                    }
                    else {
                        $NullColumns += $Col
                    }
                }
                elseif ($Value -isnot [System.DBNull]) {
                    $DR.Item($Name) = $Value
                }
                else {
                    #"Skipped since it's NULL"
                }
            } 

            Try {
                $DT.Rows.Add($DR)
            }
            Catch {
                Write-Error "Failed to add row '$($DR | Out-String)':`n$_"
                throw $_
            }
        }
    } 
     
    End {
        $columns = ($DT | Get-Member -MemberType Property).Name
        $Results = foreach ($column in $Columns) {
            $AllTypes = @()
            $max = 0
            foreach ($row in $DT) {
                $Type = $row.$column.GetType()
                $Length = $row.$column.length
                if ($AllTypes -notcontains $Type) {
                    $AllTypes += $Type
                }
                if ($max -lt $Length) {
                    $max = $Length
                }
            }
            [PSCustomObject]@{
                Name      = $column
                Types     = $AllTypes
                MaxLength = $max
            }
        }
        foreach ($Column in $Results) {
            $Col = $DT.Columns[$column.Name]
            if ($Col.DataType.Name -eq 'String') {
                $Col.MaxLength = $Column.MaxLength
            }
        }

        #Add in NULL columns
        foreach ($column in $NullColumns) {
            $Column.MaxLength = 1
            $DT.Columns.Add($Column)
        }

        Write-Output @(, $dt)
    }

}

function Get-SQLType {
    [cmdletbinding()]
    param(
        $Property,
        $Length,
        $DataType
    )

    try {
        $SQLType = switch ($DataType) {
            'String' { "NVarChar" ; break }
            'Boolean' { "Bit" ; break }
            'Byte[]' { "NVarChar" ; break }
            'Byte' { "Int" ; break }
            'Char' { "nvachar" ; break }
            'Datetime' { "DateTime" ; break }
            'Decimal' { "Decimal" ; break }
            'Double' { "BigInt" ; break }
            'Guid' { "NVarChar" ; break }
            'Int16' { "Int" ; break }
            'Int32' { "BigInt" ; break }
            'Int64' { "BigInt" ; break }
            'Single' { "BigInt" ; break }
            'UInt16' { "Int" ; break }
            'UInt32' { "BigInt" ; break }
            'UInt64' { "BigInt" ; break }
            default { "NVarChar" }
        }

        $ReturnVal = if ($SQLType -eq 'NVarChar') {
            [Microsoft.SqlServer.Management.SMO.SqlDataType]::NVarChar
        }
        elseif ($Property.TypeNameOfValue -eq 'System.Object[]') {
            [Microsoft.SqlServer.Management.SMO.SqlDataType]::NVarChar
        }
        else {
            [Microsoft.SqlServer.Management.SMO.SqlDataType]::$($SQLType)
        }
        return $ReturnVal
    }
    catch {
        $_
    }
}
#endregion

#region DataSets
$Results = $null
$Results = @()
$OBject = $Null

#Configuration Profiles
if ($ConfigurationProfiles.IsPresent) {
    Write-Host "Configuration Policies," -NoNewline
    $ConfigurationPolicies = Invoke-GraphGet -SkipNextLink -URI "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies"
    $ConfigurationPolicies2 = $ConfigurationPolicies | Select-Object -Property *, @{Name = "SettingsURL"; Expression = { "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies('$($_.id)')/settings?`$expand=settingDefinitions" } }  -ExpandProperty templateReference -ExcludeProperty templatereference
    Write-host "Saving Configuration Policies to results set"
    $Results += [pscustomobject]@{
        SystemName      = "Intune"
        Endpoint        = "ConfigurationPolicies"
        PrimaryKey      = "id"
        Data            = $ConfigurationPolicies2
    } 

    Write-Host "Configuration Settings," -NoNewline
    $i = 1
    $Configurationsettings = 
    foreach ($confpol in $ConfigurationPolicies2) {
        #write-host $confpol.settingsurl
        $setting = Invoke-GraphGet -SkipNextLink -URI $confpol.SettingsUrl #"https://graph.microsoft.com/beta/deviceManagement/configurationSettings"
        $setting2 = $setting | select-object -property *, @{Name = "PolicyID"; Expression = { $confpol.id } }, @{Name = "PolicyName"; Expression = { $confpol.Name } },@{Name = "settingsInstance"; Expression = { $setting.settingInstance | convertto-json -depth 100} },@{Name = "settingsDefinitions"; Expression = { $setting.settingDefinitions | convertto-json -depth 100} }   -ExcludeProperty id, settingDefinitions, settingInstance
        $setting3 = 
        foreach ($set in $setting2) {
            $set | select-object -property *, @{Name = "ID"; Expression = { $i } }
            $i++
        }
        $setting3

    }
    $Results += [pscustomobject]@{
        SystemName      = "Intune"
        Endpoint        = "ConfigurationSettings"
        PrimaryKey      = "id"
        Data            = $configurationSettings
    } 
    $AssignmentDefs = @()
    $i = 1
    Write-Host "Getting Configuration Settings Information," -nonewline
    $SettingDefinitions = foreach ($policy in $ConfigurationPolicies) {
        $URI = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies('$($policy.id)')/settings?`$expand=settingDefinitions&top=1000"
        $AssignmentURI = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies('$($policy.id)')/assignments"

        Do {
            try {
                $Response = Invoke-MgRestMethod -Method Get -Uri $URI -ErrorAction Continue
                $URI = $Response."@odata.nextLink"
                foreach ($item in $Response.Value) {
                    $item += @{ConfigurationPolicyId = $Policy.id }
                    $Assignments = Invoke-MgRestMethod -Method Get -Uri $AssignmentURI -ErrorAction Continue
                    $Currassignment = foreach ($assignment in $assignments.value) {
                        [PSCustomObject]$CurrObject = @{
                            Id              = $i++
                            AssignedGroupID = $assignment.target.groupID
                            AssignmentType  = $assignment.target.'@odata.type'
                            FilterID        = $assignment.target.deviceAndAppManagementAssignmentFilterId
                            FilterType      = $assignment.target.deviceAndAppManagementAssignmentFilterType
                            PolicyID        = $policy.id
                        }
                        $CurrObject
                    }
                    $AssignmentDefs += $currAssignment
                   
                    $item
                }
            }
            catch {
                $_
            }
        }
        Until ($Response."@odata.nextLink" -eq $null)
    }

    $Results += [pscustomobject]@{
        SystemName      = "Intune"
        Endpoint        = "ConfigurationPolicies_Assignments"
        PrimaryKey      = "Id"
        Data            = $AssignmentDefs
    }
    $i = 1
    $settingsObjs = foreach ($setting in $SettingDefinitions) {
        foreach ($settingInstance in $setting.settingInstance) {
            [PSCustomObject]@{
                Id                    = $i++
                ConfigurationPolicyId = $setting.ConfigurationPolicyId
                SettingInstanceId     = $settingInstance.settingDefinitionId
                SettingValue          = $settingInstance | ConvertTo-Json -Depth 100
                DisplayName           = ($configurationSettings | Where-Object id -eq $settingInstance.settingDefinitionId).displayName
            }
        }
    }

    $Results += [pscustomobject]@{
        SystemName      = "Intune"
        Endpoint        = "ConfigurationPolicies_SettingDefinitions"
        PrimaryKey      = "Id"
        Data            = $settingsObjs
    }
}

#Devices
if ($EntraDevices.IsPresent) {
    Write-Host "Entra Devices," -NoNewLine
    $AllEntraDevicesResult = Invoke-GraphGet -SkipNextLink -URI "https://graph.microsoft.com/beta/devices"
    $AllEntraDevices = $AllEntraDevicesResult | Select-Object -Property *, @{
        Name       = "ExtensionAttributeChildren"; 
        Expression = { 
            $_.extensionAttributes | Select-Object * 
        }
    } | Select-Object -ExcludeProperty extensionAttributes, ExtensionAttributeChildren, alternativeSecurityIds, '@odata.context', value -ExpandProperty ExtensionAttributeChildren | Select-Object -Property *, @{
        Name       = "Props"
        Expression = {
            [pscustomobject]@{
                'ZTDID'           = ($_.PhysicalIds -match '\[ZTDID\]' | ForEach-Object { ($_ -split ':', 2)[1] })
                'USERGID'         = ($_.PhysicalIds -match '\[USER-GID\]' | ForEach-Object { ($_ -split ':', 2)[1] })
                'GID'             = ($_.PhysicalIds -match '\[GID\]' | ForEach-Object { ($_ -split ':', 2)[1] })
                'USERHWID'        = ($_.PhysicalIds -match '\[USER-HWID\]' | ForEach-Object { ($_ -split ':', 2)[1] })
                'HWID'            = ($_.PhysicalIds -match '\[HWID\]' | ForEach-Object { ($_ -split ':', 2)[1] })
                'PurchaseOrderId' = ($_.PhysicalIds -match '\[PurchaseOrderId\]' | ForEach-Object { ($_ -split ':', 2)[1] })
            }
        }
    } | Where-Object id -ne $null | Select-Object -Property * -ExpandProperty Props -ExcludeProperty Props, PhysicalIds
    Write-Host $AllEntraDevices.count
    $Results += [pscustomobject]@{
        SystemName      = "Entra"
        Endpoint        = "Devices"
        Data            = $AllEntraDevices
    }
}

if ($IntuneDevices.IsPresent) {
    Write-Host "Intune Devices," -NoNewLine
    $AllIntuneDevices = Invoke-GraphGet -SkipNextLink -URI "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$select=id,userId,deviceName,ownerType,managedDeviceOwnerType,managementState,enrolledDateTime,lastSyncDateTime,operatingSystem,deviceType,complianceState,jailBroken,managementAgent,osVersion,easActivated,easDeviceId,aadRegistered,azureADRegistered,deviceEnrollmentType,lostModeState,emailAddress,azureActiveDirectoryDeviceId,azureADDeviceId,deviceRegistrationState,deviceCategoryDisplayName,userPrincipalName,complianceGracePeriodExpirationDateTime,androidSecurityPatchLevel,userDisplayName,managedDeviceName,partnerReportedThreatState,autopilotEnrolled,requireUserEnrollmentApproval,managementCertificateExpirationDate,joinType,skuFamily,securityPatchLevel,skuNumber,managementFeatures,bootstrapTokenEscrowed,deviceFirmwareConfigurationInterfaceManaged,usersLoggedOn"
    Write-Host $AllIntuneDevices.Count
    $Results += [pscustomobject]@{
        SystemName      = "Intune"
        Endpoint        = "Devices"
        Data            = $AllIntuneDevices
    }
}

if ($IntuneHardwareInfo.IsPresent) {
    Write-Host "IntuneHardwareInfo," -NoNewLine
    $AllIntuneDevices = Invoke-GraphGet -SkipNextLink -URI "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$select=id"
    $AllIntuneHardwareInfoResults = if ($AllIntuneDevices) {
        #region Get DeviceInformation
        $max = $AllIntuneDevices.count - 1
        $groupSize = 20
        $start = 0
        $end = $groupSize - 1

        $Response = for ($i = 0; $i -le $max; $i = $end) {
            $BatchBody = @(
                $array = if ($max -lt $groupSize) {
                    $AllIntuneDevices
                }
                else {
                    $AllIntuneDevices[$start..$end]
                }
                $array | ForEach-Object {
                    @{
                        id     = $_.ID
                        method = "GET"
                        url    = "/deviceManagement/managedDevices/$($_.id)?`$select=id,iccid,azureADDeviceId,hardwareInformation,activationLockBypassCode,notes,chassisType,easActivationDateTime,enrolledByUserPrincipalName,ethernetMacAddress,physicalMemoryInBytes,processorArchitecture,retireAfterDateTime,roleScopeTagIds,specificationVersion,udid,enrollmentProfileName,deviceHealthAttestationState"
                    }
                }
            )
            (Invoke-GraphBatch -RequestBody $BatchBody).responses
            $start = $end + 1
            $end = if ($end + $groupSize -gt $max) { $max } else { $end + $GroupSize }
            if ($start -gt $max) { break }
        } 
        $Response.body | Where-Object { $_.id -ne $Null }
    }

    
    $AllIntuneHardwareInfo = $AllIntuneHardwareInfoResults 
    | Select-Object -Property * -ExcludeProperty '@Odata.Context'
    | Select-Object -Property *, @{Name = "iccid"; Expression = { $_.iccid.replace(' ', '') } } -ExcludeProperty iccid
    | Select-Object -Property *, @{Name = "HardwareInfo"; Expression = { $_.HardwareInformation | Select-Object * } } -ExcludeProperty hardwareInformation
    | Select-Object -Property *, @{Name = "JsonNotes"; Expression = {
            if ([string]::IsNullOrEmpty($_.Notes)) {
                [pscustomobject]@{cpd_notes = $_.Notes }
            }
            else {
                try {
                    $_.Notes | ConvertFrom-Json -ErrorAction Continue
                }
                catch {
                    [pscustomobject]@{
                        cpd_InvalidJson = $true
                    }
                }
            }
        }
    }
    | Select-Object -Property *, @{Name = "roleScopeTagIds"; Expression = { $_.roleScopeTagIds } } -ExcludeProperty roleScopeTagIds
    | Select-Object -Property *, @{Name = "wiredIPv4Addresses"; Expression = { $_.wiredIPv4Addresses } } -ExcludeProperty wiredIPv4Addresses 
    | Select-Object -Property * -ExpandProperty HardwareInfo -ExcludeProperty HardwareInfo, wiredIPv4Addresses
    | Select-Object -Property * -ExcludeProperty JsonNotes -ExpandProperty JsonNotes

    Write-Host $AllIntuneHardwareInfo.count
    $Results += [pscustomobject]@{
        SystemName      = "Intune"
        Endpoint        = "Device_HardwareInfo"
        Data            = $AllIntuneHardwareInfo
    }
}

if ($AutopilotDevices.IsPresent) {    
    Write-Host "AutopilotDevices," -NoNewLine
    $AllAutopilotDevices = Invoke-GraphGet -SkipNextLink -URI "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities"
    Write-Host $AllAutopilotDevices.Count
    $Results += [pscustomobject]@{
        SystemName      = "Intune"
        Endpoint        = "AutoPilotDevices"
        Data            = $AllAutopilotDevices
    } 
}

if ($IntuneDeviceCategories.IsPresent) {
    Write-Host "IntuneDeviceCategories," -NoNewLine
    $AllDeviceCategories = Invoke-GraphGet -SkipNextLink -URI "https://graph.microsoft.com/beta/deviceManagement/deviceCategories"
    Write-Host $AllDeviceCategories.Count
    $Results += [pscustomobject]@{
        SystemName      = "Intune"
        Endpoint        = "DeviceCategories"
        Data            = $AllDeviceCategories
    }
}

if ($IntuneDepOnboardingSettings.IsPresent) {
    Write-Host "IntuneDepOnboardingSettings," -NoNewLine
    $AllDepOnboardingSettings = Invoke-GraphGet -SkipNextLink -URI "https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings"
    Write-Host $AllDepOnboardingSettings.Count
    $AllImportedAppleDeviceIdentities = foreach ($Setting in ($AllDepOnboardingSettings | Where-Object { $_.syncedDeviceCount -gt 0 })) {
        $Objs = Invoke-GraphGet -SkipNextLink -URI "https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings/$($setting.id)/importedAppleDeviceIdentities?`$filter=discoverySource%20eq%20%27deviceEnrollmentProgram%27"
        foreach ($obj in $Objs) {
            $obj | Add-Member -MemberType NoteProperty -Name 'depOnboardingSettingId' -Value $Setting.id
            $obj | Add-Member -MemberType NoteProperty -Name 'depOnboardingSettingtokenName' -Value $Setting.tokenName
            $obj
        }
    }
    $Results += [pscustomobject]@{
        SystemName      = "Intune"
        Endpoint        = "Apple_DEPDevices"
        Data            = $AllImportedAppleDeviceIdentities
    }
}

if ($EntraDeviceLapsInfo.IsPresent) {
    Write-Host "EntraDeviceLapsInfo," -NoNewLine
    $AllLAPSDevices = Invoke-GraphGet -SkipNextLink -URI "https://graph.microsoft.com/beta/deviceLocalCredentials?`$select=id,deviceName,lastBackupDateTime,refreshDateTime"
    Write-Host $AllLAPSDevices.Count
    $Results += [pscustomobject]@{
        SystemName      = "Entra"
        Endpoint        = "LAPSInfo"
        Data            = $AllLAPSDevices
    }
}

if ($IntuneAssignmentFilters.IsPresent) {
    Write-Host "IntuneAssignmentFilters," -NoNewLine
    $AllAssignmentFilters = Invoke-GraphGet -SkipNextLink -URI "https://graph.microsoft.com/beta/deviceManagement/assignmentFilters"
    Write-Host $AllAssignmentFilters.Count
    $Results += [pscustomobject]@{
        SystemName      = "Intune"
        Endpoint        = "AssignmentFilters"
        Data            = $AllAssignmentFilters
    } 
}

if ($IntuneRoleScopeTags.IsPresent) {
    Write-Host "IntuneRoleScopeTags," -NoNewLine
    $AllRoleScopeTags = Invoke-GraphGet -SkipNextLink -URI "https://graph.microsoft.com/beta/deviceManagement/roleScopeTags"
    Write-Host $AllRoleScopeTags.Count
    $Results += [pscustomobject]@{
        SystemName      = "Intune"
        Endpoint        = "RoleScopeTags"
        Data            = $AllRoleScopeTags
    } 
}

#Users
if ($EntraUsers.IsPresent) {
    Write-Host "EntraUsers," -NoNewLine
    $AllEntraUsers = Invoke-GraphGet -SkipNextLink -URI "https://graph.microsoft.com/beta/users?`$expand=manager(`$select=id)&`$select=id,deletedDateTime,accountEnabled,ageGroup,businessPhones,city,createdDateTime,creationType,companyName,consentProvidedForMinor,country,department,displayName,employeeId,employeeHireDate,employeeLeaveDateTime,employeeType,faxNumber,givenName,isManagementRestricted,isResourceAccount,jobTitle,legalAgeGroupClassification,mail,mailNickname,mobilePhone,onPremisesDistinguishedName,officeLocation,onPremisesDomainName,onPremisesImmutableId,onPremisesLastSyncDateTime,onPremisesSecurityIdentifier,onPremisesSamAccountName,onPremisesSyncEnabled,onPremisesUserPrincipalName,passwordPolicies,postalCode,preferredDataLocation,preferredLanguage,refreshTokensValidFromDateTime,securityIdentifier,showInAddressList,signInSessionsValidFromDateTime,state,streetAddress,surname,usageLocation,userPrincipalName,externalUserConvertedOn,externalUserState,externalUserStateChangeDateTime,userType"
    Write-Host $AllEntraUsers.Count
    $Results += [pscustomobject]@{
        SystemName      = "Entra"
        Endpoint        = "Users"
        Data            = $AllEntraUsers | Select-Object -Property *, @{Name = 'managerId'; Expression = { $_.manager.id } } -ExcludeProperty manager, '@odata.context', value
    }
}

if ($EntraUsersSignInLogs.IsPresent) {
    Write-Host "EntraUsersSignInLogs," -NoNewLine
    $FilterDate = (Get-Date -AsUTC).AddHours(-1).toString("o").ToString()
    $AllEntraUsersSignInLogs = Invoke-GraphGet -SkipNextLink -URI "https://graph.microsoft.com/beta/auditLogs/signIns?`$filter=createdDateTime ge $($FilterDate) and appDisplayName eq 'Windows Sign In'"
    Write-Host $AllEntraUsersSignInLogs.Count
    $Results += [pscustomobject]@{
        SystemName      = "Entra"
        Endpoint        = "SignInLogs"
        AppendData      = $True
        Data            = $AllEntraUsersSignInLogs | Select-Object id, userID, userDisplayName, UserPrincipalName, @{Name = "deviceName"; Expression = { $_.deviceDetail.displayName } }, @{Name = "deviceId"; Expression = { $_.deviceDetail.deviceId } }, createdDateTime
    }
}

#Groups
if ($EntraGroups.IsPresent) {
    Write-Host "EntraGroups," -NoNewLine
    $AllEntraGroups = Invoke-GraphGet -SkipNextLink -URI "https://graph.microsoft.com/beta/groups"
    Write-Host $AllEntraGroups.Count
    $Results += [pscustomobject]@{
        SystemName      = "Entra"
        Endpoint        = "Groups"
        Data            = $AllEntraGroups
    }
}

#Apps
if ($IntuneMobileApps.IsPresent) {
    #region MobileApps
    Write-Host "MobileApps," -NoNewline
    $AllMobileApps = Invoke-GraphGet -SkipNextLink -URI "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps"
    Write-Host $AllMobileApps.count
    $Results += [pscustomobject]@{
        SystemName      = "Intune"
        Endpoint        = "MobileApps"
        Data            = $AllMobileApps
    } 
    #endregion

    #region AppAssignments
    Write-Host "AppAssignments," -NoNewline
    $AssignmentResults = if ($AllMobileApps) {
        $max = $AllMobileApps.count - 1
        $groupSize = 20
        $start = 0
        $end = $groupSize - 1

        $Response = for ($i = 0; $i -le $max; $i = $end) {
            $BatchBody = @(
                $array = if ($max -lt $groupSize) {
                    $AllMobileApps
                }
                else {
                    $AllMobileApps[$start..$end]
                }
                $array | ForEach-Object {
                    @{
                        id     = $_.ID
                        method = "GET"
                        url    = "/deviceAppManagement/mobileApps/$($_.id)/assignments"
                    }
                }
            )
            (Invoke-GraphBatch -RequestBody $BatchBody).responses
            $start = $end + 1
            $end = if ($end + $groupSize -gt $max) { $max } else { $end + $GroupSize }
            if ($start -gt $max) { break }
        } 
    
        $Response
    }

    $AssignmentObjects = $AssignmentResults | Where-Object { $_.body.value -ne $null } | Select-Object @{
        name       = 'AppId'; 
        Expression = { $_.id };
    }, 
    @{
        name       = 'value'; 
        expression = { $_.body.value };
    } 

    $Assignments = $AssignmentObjects | Select-Object -Property * -ExpandProperty value -ExcludeProperty value

    $AllAppsAssignments = $Assignments | ForEach-Object {
        [pscustomobject] @{
            assignmentId                                     = "$($_.id)"
            appId                                            = $_.AppId
            intent                                           = $_.intent
            source                                           = $_.source
            targetType                                       = $_.target.'@odata.type'
            targetdeviceAndAppManagementAssignmentFilterId   = $_.target.deviceAndAppManagementAssignmentFilterId
            targetdeviceAndAppManagementAssignmentFilterType = $_.target.deviceAndAppManagementAssignmentFilterType
            targetgroupId                                    = $_.target.GroupId
            settingsType                                     = $_.settings.'@odata.type'
            settingsnotifications                            = $_.settings.notifications
            settingsrestartSettings                          = $_.settings.restartSettings
            settingsinstallTimeSettings                      = $_.settings.installTimeSettings
            settingsdeliveryOptimizationPriority             = $_.settings.deliveryOptimizationPriority
            settingsautoUpdateSettings                       = $_.settings.autoUpdateSettings
        }
    }

    Write-Host $AllAppsAssignments.count
    $Results += [pscustomobject]@{
        SystemName      = "Intune"
        Endpoint        = "MobileApps_Assignments"
        Data            = $AllAppsAssignments
    }
    #endregion
}

if ($IntuneAppStatusReport.IsPresent) {
    Write-Host "IntuneAppStatusReport," -NoNewline
    #region AppStatusOverviewReport
    $start = 0
    $max = 51
    $i = 0
    $StatusResponse = do {
        $body = @{
            select  = @("DisplayName", "Publisher", "Platform", "AppVersion", "FailedDevicePercentage", "FailedDeviceCount", "FailedUserCount", "InstalledDeviceCount", "InstalledUserCount", "PendingInstallDeviceCount", "PendingInstallUserCount", "NotApplicableDeviceCount", "NotApplicableUserCount", "NotInstalledDeviceCount", "NotInstalledUserCount", "ApplicationId")
            skip    = $i
            top     = 50
            filter  = $null
            orderBy = @()
        }
        $response = (Invoke-GraphPost -Uri "https://graph.microsoft.com/beta/deviceManagement/reports/getAppsInstallSummaryReport" -Body $Body -OutputFilePath ".\graphStatusReport.csv")
        Start-Sleep -seconds 10
        $max = $response.TotalRowCount
        $schema = $response.Schema
        $i = $i + 50
        $response.values
    } until ($i -ge $max -or $max -eq $null)

    $StatusResults = $StatusResponse | foreach-object -Begin { $propertyNames = @($schema.Column) } -Process { $properties = [ordered] @{}; for ( $i = 0; $i -lt $Schema.Length; $i++ ) { $properties[$propertyNames[$i]] = $_[$i]; }new-object PSCustomObject -Property $properties }

    Write-Host $StatusResults.count
    $Results += [pscustomobject]@{
        SystemName      = "Intune"
        Endpoint        = "MobileApps_StatusOverviewReport"
        PrimaryKey      = "ApplicationId"
        Data            = $StatusResults
    }
    #endregion
}


#WindowsUpdateInfo
<# if ($WindowsUpdateInfo.IsPresent -or $WindowsUpdatesProductsRevisions.IsPresent -or $WindowsUpdatesProductsEditions.IsPresent) {
    #region WindowsUpdatesProducts
    Write-Host "WindowsUpdatesProducts," -NoNewline
    $WindowsUpdatesProducts = Invoke-GraphGet -SkipNextLink -URI "https://graph.microsoft.com/beta/admin/windows/updates/products"
    $WindowsUpdatesProducts = $WindowsUpdatesProducts | Select-Object -ExcludeProperty Length, FriendlyNames -Property *, @{
        Name       = "OSBuild";
        Expression = { ($_.friendlyNames | Where-Object { $_ -like '*OS build*' }) | foreach-Object { [regex]::Match($_, ".*build (\d+)(\))").Groups[1].Value } }
    },
    @{
        Name       = "OSVersion";
        Expression = { if ($_.Name -notlike '*Server*') {
                                ($_.Name.Split(','))[1].Split(' ')[2]
            }
            else {
                $_.Name.Replace(' and ', ';')
            }
        }
    }
    Write-Host $WindowsUpdatesProducts.count

    $Results += [pscustomobject]@{
        SystemName      = "WindowsUpdates"
        Endpoint        = "Products"
        Data            = $WindowsUpdatesProducts
    }
    #endregion
}

if ($WindowsUpdatesProductsRevisions.IsPresent) {
    #region WindowsUpdatesProductsRevisions
    Write-Host "WindowsUpdatesProductsRevisions," -NoNewline
    $WindowsUpdatesProductsRevisions = foreach ($product in $WindowsUpdatesProducts) {
        $revisions = Invoke-GraphGet -SkipNextLink -URI "https://graph.microsoft.com/beta/admin/windows/updates/products/$($product.id)?`$expand=revisions"
        foreach ($revision in $revisions.revisions) {
            [PSCustomObject]@{
                id                  = $revision.id
                productId           = $product.id
                displayName         = $revision.displayName
                releaseDateTime     = $revision.releaseDateTime
                version             = $revision.version
                product             = $revision.product
                majorVersion        = $revision.osBuild.majorVersion
                minorVersion        = $revision.osBuild.minorVersion
                buildNumber         = $revision.osBuild.buildNumber
                updateBuildRevision = $revision.osBuild.updateBuildRevision
                kbId                = $revision.knowledgeBaseArticle.id
                kbUrl               = $revision.knowledgeBaseArticle.url
            }
        }
    }

    Write-Host $WindowsUpdatesProductsRevisions.count
    $Results += [pscustomobject]@{
        SystemName      = "WindowsUpdates"
        Endpoint        = "ProductsRevisions"
        Data            = $WindowsUpdatesProductsRevisions
    }
    #endregion
}

if ($WindowsUpdatesProductsEditions.IsPresent) {
    #region WindowsUpdatesProductsEditions
    Write-Host "WindowsUpdatesProductsEditions," -NoNewline
    $WindowsUpdatesProductsEditions = foreach ($product in $WindowsUpdatesProducts) {
        $editions = Invoke-GraphGet -SkipNextLink -URI "https://graph.microsoft.com/beta/admin/windows/updates/products/$($product.id)?`$expand=editions"
        foreach ($edition in $editions.editions) {
            [PSCustomObject]@{
                id                          = $edition.id
                productId                   = $product.id
                name                        = $edition.name
                releasedName                = $edition.releasedName
                deviceFamily                = $edition.deviceFamily
                isInService                 = $edition.isInService
                generalAvailabilityDateTime = $edition.generalAvailabilityDateTime
                endOfServiceDateTime        = $edition.endOfServiceDateTime
                SKUNumber                   = $edition.id.split('_')[1]
                SKUNumberExtended           = $edition.id.split('_')[2]
                #servicingPeriods             = $edition.servicingPeriods
                #servicingPeriodName          = $edition.servicingPeriods.name                    
                #servicingPeriodStartDateTime = $edition.servicingPeriods.startDateTime                        
                #servicingPeriodEndDateTime   = $edition.servicingPeriods.endDateTime                        
            }
        }
    }
    Write-Host $WindowsUpdatesProductsEditions.count
    $Results += [pscustomobject]@{
        SystemName      = "WindowsUpdates"
        Endpoint        = "ProductsEditions"
        Data            = $WindowsUpdatesProductsEditions
    }
    #endregion
}
 #>
if ($AppleModelInfo.IsPresent) {
    Write-Host "AppleModelInfo," -NoNewline

    $Uri = "https://api.appledb.dev/device/main.json"
    $DeviceList = Invoke-RestMethod -Uri $Uri

    $DeployedDevices = @(
        'iPhone16,2'
        'iPhone17,1'
        'iPhone17,2'
        'iPhone17,3'
        'iPhone17,4'
        'iPhone17,5'
    )

    $AllAppleModels = $DeviceList | Where-Object identifier -in $DeployedDevices | Select-Object Name, @{Name = "id"; Expression = { $_.identifier } }, arch, type, @{Name = "board"; Expression = { $_.board } }, @{Name = "model"; Expression = { $_.model -join (',') } }, @{Name = "released"; Expression = { $_.released -join (',') } }, soc -ExcludeProperty identifier, info, board, model
    Write-Host $AllAppleModels.Count

    $Results += [pscustomobject]@{
        SystemName = "Apple"
        Endpoint   = "Models"
        Data       = $AllAppleModels
    }
}
#endregion

#region Variables
$SqlInstance = "cm01.asd.net"
$Database = "MMSFLL"
$Script:SQLLastImported = [datetime](Get-Date)
#endregion

#region main
if (-not [Microsoft.Graph.PowerShell.Authentication.GraphSession]::Instance.AuthContext.Scopes) {
    Connect-MgGraph -Scopes "AuditLog.Read.All","CloudPC.ReadWrite.All","CloudPC.ReadWrite.All","Device.Read.All","Device.ReadWrite.All","DeviceManagementApps.ReadWrite.All","DeviceManagementApps.ReadWrite.All","DeviceManagementConfiguration.ReadWrite.All","DeviceManagementConfiguration.ReadWrite.All","DeviceManagementManagedDevices.PrivilegedOperations.All","DeviceManagementManagedDevices.PrivilegedOperations.All","DeviceManagementManagedDevices.ReadWrite.All","DeviceManagementManagedDevices.ReadWrite.All","DeviceManagementRBAC.ReadWrite.All","DeviceManagementRBAC.ReadWrite.All","DeviceManagementServiceConfig.ReadWrite.All","DeviceManagementServiceConfig.ReadWrite.All","Group.ReadWrite.All","Group.ReadWrite.All","GroupMember.ReadWrite.All","GroupMember.ReadWrite.All","Policy.Read.All","Reports.Read.All","Reports.Read.All","User.Read.All","User.ReadWrite.All","WindowsUpdates.ReadWrite.All"
}

$Null = Set-DbatoolsInsecureConnection -SessionOnly
#$Server = Connect-DbaInstance -SqlInstance $SqlInstance -Database $Database -NonPooledConnection

foreach ($Object in $Results) {
    $TableName = "t_$($Object.SystemName)_$($Object.Endpoint)"
    #$TableExists = $server.ConnectionContext.ExecuteScalar("SELECT TOP(1) 1 FROM [$tableName]")
    
    $Object = Get-ObjectPropertyInfo -Object $Object
    
    #If you want to use properly typed and sized columns, use these lines. Also PowerShell objects will be converted to JSON.
    #Write-DbaDbTableData -SqlInstance $SqlInstance -Database $Database -Table $TableName -AutoCreateTable -InputObject $Object.Data -Truncate -UseDynamicStringLength -NotifyAfter 1000 -KeepNulls -ColumnMap $OBject.PropList
    
    #If you don't care about types and sizes, use these lines and all String types will be resized to NVarChar(MAX). Also PowerShell objects won't be converted to text.
    Write-DbaDbTableData -SqlInstance $SqlInstance -Database $Database -Table $TableName -AutoCreateTable -InputObject $Object.Data -Truncate -NotifyAfter 1000 -KeepNulls

}

#endregion
