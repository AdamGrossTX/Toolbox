#DO NOT USE > Work in Progress
#Client Inventory Script
param(
    $AzureFunctionURI,
    $azureFunctionSecret,
    $DceURI,
    $DcrImmutableId,
    $Table
)

function Get-AADDeviceID {
    [cmdletbinding()]
    param()
    try {
        $AADDeviceID = $null
        $Path = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo"
        $Key = Get-ChildItem -Path REGISTRY::$Path
        if($Key) {
            $AADDeviceThumbprint = $Key.PSChildName
            $AzureCert = Get-ChildItem -Path "cert:\LocalMachine\My" | Where-Object {$_.Thumbprint -eq $AADDeviceThumbprint}
            if($AzureCert) {
                $AADDeviceID = ($AzureCert.SubjectName.Name.Split(',') | Where-Object {$_ -like 'CN=*'} | Select-Object -Unique).trim().Replace('CN=','')
            }
        }
        return $AADDeviceID
    }
    catch {
        throw $_
    }
}

function Get-IntuneDeviceID {
    [cmdletbinding()]
    param()
    try {
        $IntuneDeviceID = $null
        $ProviderKey = Get-ChildItem -Path registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments" -Recurse | Where-Object {$_.GetValueNames() -eq "EntDMID"}
        if($ProviderKey) {
            $IntuneDeviceID = $ProviderKey.GetValue("EntDMID")
        }
        return $IntuneDeviceID
    }
    catch {
        throw $_
    }
}

#Source: https://github.com/okieselbach/Intune/blob/master/Convert-AzureAdSidToObjectId.ps1
function Convert-AzureAdSidToObjectId {
    [cmdletbinding()]
    param([String] $Sid)

    $text = $sid.Replace('S-1-12-1-', '')
    $array = [UInt32[]]$text.Split('-')

    $bytes = New-Object 'Byte[]' 16
    [Buffer]::BlockCopy($array, 0, $bytes, 0, 16)
    [Guid]$guid = $bytes

    return $guid
}

try {
    $appName = 'UserSoftwareInventoryScript'
    $AzureADID = Get-AADDeviceID
    $IntuneID = Get-IntuneDeviceID
    $UserSID = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
    $AzureIDUserID =  Convert-AzureAdSidToObjectId -Sid $UserSID
    $UserUPN = whoami /upn

    $Path = "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall"
    $Keys = Get-ChildItem -Path REGISTRY::$Path
    
    $InventoryObjects = foreach($key in $Keys) {
        $Properties = $key | Get-ItemProperty
        
        $Properties | Add-Member -MemberType NoteProperty -Name "Application" -Value $appName
        $Properties | Add-Member -MemberType NoteProperty -Name "RegKeyPath" -Value $Key.Name
        $Properties | Add-Member -MemberType NoteProperty -Name "RegKeyName" -Value $Key.PSChildName
        $Properties | Add-Member -MemberType NoteProperty -Name "AzureADDeviceID" -Value $AzureADID
        $Properties | Add-Member -MemberType NoteProperty -Name "IntuneDeviceID" -Value $IntuneID
        $Properties | Add-Member -MemberType NoteProperty -Name "DeviceName" -Value $env:COMPUTERNAME
        $Properties | Add-Member -MemberType NoteProperty -Name "UserName" -Value $ENV:USERNAME
        $Properties | Add-Member -MemberType NoteProperty -Name "UserDomain" -Value $env:USERDOMAIN
        $Properties | Add-Member -MemberType NoteProperty -Name "UserUPN" -Value $UserUPN
        $Properties | Add-Member -MemberType NoteProperty -Name "AzureADUserID" -Value $AzureIDUserID
        $Properties
    }
    
    $LogParams = @{
        DceURI         = $DceURI
        DcrImmutableId = $DcrImmutableId
        Table          = $Table
        #TODO: Convert LogEntry into a blob that can be sent in the url as a payload.
        LogEntry       = $InventoryObjects | Select-Object DisplayIcon, DisplayName, DisplayVersion, ApplicationVersion, InstallDate, Publisher, UninstallString, NoRepair, NoModify, Application, RegKeyPath, RegKeyNameAzureADDeviceID, IntuneDeviceID, DeviceName, UserName, UserDomain, UserUPN, AzureADUserID
    }

    $FunctionResponse = Invoke-WebRequest -uri "$($AzureFunctionURI)?code=$azureFunctionSecret&DceURI=$LogParams.DceURI&DcrImmutableId=$LogParams.DcrImmutableId&Table=$LogParams.Table&LogEntry=$LogParams.LogEntry"

    #TODO: Add Logging Here
    Write-Host $FunctionResponse
}
catch {
    throw $_
}
