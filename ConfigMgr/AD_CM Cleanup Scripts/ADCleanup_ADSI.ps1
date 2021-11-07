#This is a work in progress.  Use at your own risk.
#By: AdamGrossTX

Param (
    [cmdletbinding]

    [parameter]
    [switch]$DebugMode = $True,
    
    [parameter]
    [int]$ActiveMax = 121,    #This is the maximum password age/inactive days before the machine is considered eligible for being disabled.
    
    [parameter]
    [int]$InactiveMax = 365,#This is the maximum password age/inactive days before the machine is considered eligible for being deleted.
    
    [parameter]
    [string]$ServerName, # SMS Provider machine name
    
    [parameter]
    [string[]]$OUNameFilter,
    
    [parameter]
    [string[]]$OUDNFilter,
    
    [parameter]
    [string]$SiteCode,
    
    [parameter]
    [string[]]$Domain,

    [string[]]$Mode (
        'Enable',
        'Disable',
        'Delete',
        'Audit'
    )
    [switch]$ProcessAD,
    [switch]$ProcessCM,
    [switch]$ProcessUsers,
    [switch]$ProcessComputers
)

#region variables
$Date = Get-Date -Format d | ForEach-Object {$_ -replace "/", "_"}
$ActiveMaxDateTime = (Get-Date).AddDays(-$ActiveMax)
$InactiveMaxDateTime = (Get-Date).AddDays(-$InactiveMax)
$NameSpace = "root\SMS\SITE_$($SiteCode)"
#endregion

#region Helper Functions
function ConvertFrom-IADSLargeInteger {
#https://social.technet.microsoft.com/Forums/en-US/76c3797f-871b-4d62-b78a-a42e02b13e4c/powershell-ldap-and-the-iadslargeinteger-interface?forum=ITCG
#bill stewart
param(
    [System.__ComObject] $adsLargeInteger
)
    $highPart = $adsLargeInteger.GetType().InvokeMember("HighPart","GetProperty",$NULL,$adsLargeInteger,$NULL)
    $lowPart = $adsLargeInteger.GetType().InvokeMember("LowPart","GetProperty",$NULL,$adsLargeInteger,$NULL)
    $highBytes = [System.BitConverter]::GetBytes($highPart)
    $lowBytes = [System.BitConverter]::GetBytes($lowPart)
    [datetime]::FromFileTime([System.BitConverter]::ToUInt64($lowBytes + $highBytes, 0))
}
#endregion

#region ASDI Functions
function Get-OU {
param(
    [string]$OUNameFilter,
    [string]$OUDNFilter,
    [string]$DomainName
)
    $DomainDistinguishedName = "LDAP://$DomainName"
    $Search = New-Object -TypeName System.DirectoryServices.DirectorySearcher -ErrorAction 'Stop'
    $Search.SizeLimit = $SizeLimit
    $Search.SearchRoot = $DomainDistinguishedName
    $Search.Filter = 
        if($OUNameFilter) {
            "(&(objectCategory=organizationalunit)(name=$OUNameFilter))"
        }
        elseif($OUDNFilter) {
            "(&(objectCategory=organizationalunit)(distinguishedname=$OUDNFilter))"
        }
    $SearchResults = $Search.FindAll()
    $DirectoryEntry = $SearchResults.GetDirectoryEntry()
    $DirectoryEntry.RefreshCache("canonicalName")
    return $DirectoryEntry
}
#endregion

}
function Update-ADComputers {
param (
    $ADComputers,
    
    [ValidateSet("Disable","Delete","Enable")]
    [string]$Type     
)
    try {
        foreach($adsiDevice in $ADComputers) {
            switch ($type) {
                "Disable" {
                    if($adsiDevice.Description[0] -ne $null -and $adsiDevice.Description[0] -ne '') {
                        $adsiDevice.Put("description",($adsiDevice.Description[0] -replace 'Retired[^,]*,|Installed[^,]*,', "Retired BY ADSync $((Get-Date -format d).ToString()),"))
                    } else {
                        $adsiDevice.Put("description","Retired BY ADSync $((Get-Date -format d).ToString()),")
                    }
                    if(($adsiDevice.useraccountcontrol.value -band 2) -eq 0) {
                        $adsiDevice.userAccountControl.value = ($adsiDevice.userAccountControl.value -bor 2)
                    }
                    else {
                        $AlreadyDisabled += $Computer
                    }

                    if(-not $DebugMode) {
                        $adsiDevice.SetInfo()
                        $adsiDevice.RefreshCache()
                    }
                    else {
                        Write-Output "Would have disabled: $($adsiDevice.Name)"
                    }
                    break;
                }
                "Enable" {
                    if($adsiDevice.Description[0] -ne $null -and $adsiDevice.Description[0] -ne '') {
                        $adsiDevice.Put("description",($adsiDevice.Description[0] -replace 'Retired[^,]*,|Enabled[^,]*,', "Enabled By ADSync $((Get-Date -format d).ToString()),"))
                    } else {
                        $adsiDevice.Put("description","Enabled By ADSync $((Get-Date -format d).ToString()),")
                    }
                    if(($adsiDevice.useraccountcontrol.value -band 2) -eq 2) {
                        $adsiDevice.userAccountControl.value = ($adsiDevice.userAccountControl.value -bxor 2)
                    }
                    else {
                        $AlreadyEnabled += $Computer
                    }
                    if(-not $DebugMode) {
                        $adsiDevice.SetInfo()
                        $adsiDevice.RefreshCache()
                    }
                    else {
                        Write-Output "Would have enabled: $($adsiDevice.Name)"
                    }
                    break;
                }
                "Delete" {
                    if(-not $DebugMode) {
                        $adsiDevice.DeleteTree()
                        break;
                    }
                    else {
                        Write-Output "Would have enabled: $($adsiDevice.Name)"
                    }
                }
            }
        }
    }
    catch {
        throw $_
    }
}
function Delete-SCCMObjects {
param (
    $ComputerList
)
    foreach ($Computer in $ComputerList)
    {
        if($Computer.PSobject.Properties.Name -contains "Name") {
           $ComputerName = $Computer.Name
        }
        elseif($Computer.PSobject.Properties.Name -contains "InputObject") {
            $ComputerName = $Computer.InputObject
        }
        else {$ComputerName = $null}
        
        if(-not $DebugMode){
            try {
                #Get-CMDevice -Name $ComputerName | Remove-CMDevice -Force -ErrorAction stop
            }
            catch {
                throw $_
            }
        }
    }
    Set-Location $PSScriptRoot
}

#region Main
if (-not (Get-Module -Name ActiveDirectory)) { Import-Module -Name ActiveDirectory -ErrorAction Stop}
Add-Type -AssemblyName System.DirectoryServices.AccountManagement

ForEach($Domain in $DomainList) {
    #$OUList += Get-ADSIOrganizationalUnit -Name "$($OUFilter)" -DomainDistinguishedName $Domain -SizeLimit 5000
    $OUDirectoryEntries = 
        if($OUDNFilter) {
            foreach($filter in $OUDNFilter) {
                Get-OU -OUDNFilter $filter -DomainName $Domain                
            }
        }
        if($OUNameFilter) {
            foreach($filter in $OUNameFilter) {
                Get-OU -OUNameFilter $filter -DomainName $Domain
            }
        }
    $OUList = foreach($OU in $OUDirectoryEntries) {
        [PSCustomObject]@{
            ADSIObject = $OU
            Name = $OU.name
            DistinguishedName = $OU.distinguishedName
            CanonicalName = $OU.canonicalName
            Computers = $OU.children
        }
    }
}

$ADComputerList = [PSCustomObject]@{
    Computers = $null
    Inactive = $null
    Disabled = $null
    NoLastLogonTimeStamp = $null
    NoPwdLastSet = $null
    PasswordLastSetDisable = $null
    PasswordLastSetDelete = $null
    PasswordLastSetReEnable = $null
    ToDisable = $null
    ToDelete = $null
    ToReEnable = $null
}

$CMDeviceList = [PSCustomObject]@{
    Devices = $null
    FilteredDevices = $null
    CompareCMtoAD = $null
    InCMNotInAD = $null
    InADNotInCM = $null
    ADDisabled = $null
    ADToDisable = $null
    ADToDelete = $null
    DeleteFromCM = $null
    NoDistinguishedName = $null # These likely need to be deleted too, but we have to be careful since they could be pre-imports or something.  Need to use last date stamp or something to be sure.
}

if($OUList.Computers) {
    $ADComputerList.Computers = $OUList.Computers
    $ADComputerList.Inactive = $ADComputerList.Computers | Where-Object { $_.Properties.lastlogontimestamp } | Where-Object {(ConvertFrom-IADSLargeInteger $_.lastlogontimestamp[0]) -lt $ActiveMaxDateTime}
    $ADComputerList.Disabled = $ADComputerList.Computers | Where-Object { $_.Properties.useraccountcontrol } | Where-Object {($_.Properties.useraccountcontrol[0] -band 2) -ne 0}
    $ADComputerList.NoLastLogonTimeStamp = $ADComputerList.Computers | Where-Object { -not ($_.Properties.lastlogontimestamp) }
    $ADComputerList.NoPwdLastSet = $ADComputerList.Computers | Where-Object { -not ($_.Properties.pwdlastset) }
    $ADComputerList.ToDisable = $ADComputerList.Inactive | Where-Object {(ConvertFrom-IADSLargeInteger $_.pwdlastset[0]) -le $ActiveMaxDateTime -and (ConvertFrom-IADSLargeInteger $_.pwdlastset[0]) -gt $InactiveMaxDateTime}
    $ADComputerList.ToDelete = $ADComputerList.Inactive | Where-Object {(ConvertFrom-IADSLargeInteger $_.pwdlastset[0]) -le $InactiveMaxDateTime}
    $ADComputerList.ToReEnable = $ADComputerList.Disabled | Where-Object {(ConvertFrom-IADSLargeInteger $_.pwdlastset[0]) -ge $ActiveMaxDateTime}
}

$CMDeviceList.Devices = Get-CIMInstance -Namespace $NameSpace -ClassName "SMS_R_System" -ComputerName $ServerName -Property @("ResourceID","Name","SystemOUName","DistinguishedName","AgentTime") | Sort-Object Name
if($CMDeviceList.FilteredDevices -and $ADComputerList.Computers) {
    $CMDeviceList.FilteredDevices = foreach($OU in $OUList) {$CMDeviceList.Devices | Where-Object {$_.SystemOUName -eq $OU.CanonicalName}}
    $CMDeviceList.CompareCMtoAD = Compare-Object -ReferenceObject @($CMDeviceList.FilteredDevices | Select-Object) -DifferenceObject @($ADComputerList.Computers | Select-Object) -Property Name -IncludeEqual -PassThru
    $CMDeviceList.InCMNotInAD = $CMDeviceList.CompareCMtoAD | Where-Object {$_.SideIndicator -eq '<='}
    $CMDeviceList.InADNotInCM = $CMDeviceList.CompareCMtoAD | Where-Object {$_.SideIndicator -eq '=>'}
    $CMDeviceList.ADDisabled = Compare-Object -ReferenceObject @($CMDeviceList.FilteredDevices | Select-Object) -DifferenceObject @($ADComputerList.Disabled | Select-Object) -Property Name -IncludeEqual -ExcludeDifferent -PassThru
    $CMDeviceList.ADToDisable = Compare-Object -ReferenceObject @($CMDeviceList.FilteredDevices | Select-Object) -DifferenceObject @($ADComputerList.ToDisable | Select-Object) -Property Name -IncludeEqual -ExcludeDifferent -PassThru
    $CMDeviceList.ADToDelete = Compare-Object -ReferenceObject @($CMDeviceList.FilteredDevices | Select-Object) -DifferenceObject @($ADComputerList.ToDelete | Select-Object) -Property Name -IncludeEqual -ExcludeDifferent -PassThru
    $CMDeviceList.DeleteFromCM = $CMDeviceList.ADDisabled + $CMDeviceList.ADToDisable + $CMDeviceList.ADToDelete
    $CMDeviceList.NoDistinguishedName = $CMDeviceList.Devices | Where-Object {$_.DistinguishedName -eq $null}
}

#TODO
#Add AD and CM User Processing or at least counting, etc.

#Still Need to work this out
#Process-ADComputers -ADComputers $ADComputersToDelete -Type Delete
#Process-ADComputers -ADComputers $ADComputersToDisable -Type Disable
#Process-ADComputers -ADComputers $ADComputersToEnable -Type Enable
#Process-ADComputers -ADComputers $ADRetiredComputers -Type Disable

#Delete-SCCMObjects $CMAllDeleted
#Delete-SCCMObjects $InCMNotInAD
#Delete-SCCMObjects $DeleteFromCM

#Output-Results
#endregion
#Remove-Variable * -ErrorAction SilentlyContinue

$ADComputerList
$CMDeviceList