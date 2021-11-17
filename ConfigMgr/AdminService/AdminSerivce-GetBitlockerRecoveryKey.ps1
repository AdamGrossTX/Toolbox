[cmdletbinding()]
param(
    [int]$ResourceID,
    [string]$SMSProvider
)

#region AdminService URLs
[string]$VersionedBaseUrl       = "https://$($SMSProvider)/AdminService/v1.0"
[string]$DeviceClassURL         = "$($VersionedBaseUrl)/Device"
#endregion

#AdminService
$asGetParams = @{
    Method                = "GET"
    ContentType           = "application/json"
    ErrorAction           = "SilentlyContinue"
    UseDefaultCredentials = $True
}

$asPostParams = @{
    Method                = "POST"
    ContentType           = "application/json"
    ErrorAction           = "SilentlyContinue"
    UseDefaultCredentials = $True
}
#endregion


    #region Get ConfigMgr Device
        try{
            $asGetParams["URI"] = "$($DeviceClassURL)($($ResourceID))"
            $CMDeviceResponse = Invoke-RestMethod @asGetParams
            if ($CMDeviceResponse) {
                $CMDevice = $CMDeviceResponse
                Write-Output "Found ConfigMgr Device: $($CMDevice.Name)"
            }
        }
        catch {
            Write-Output "No CM Device found for device: $($ManagedDevice.deviceName)"
        }

        if ($CMDevice) {
            try {
                $asGetParams["URI"] = "$($DeviceClassURL)($($CMDevice.MachineId))/RecoveryKeys"
                $RecoveryKeyResponse = Invoke-RestMethod @asGetParams
                $RecoveryKeys = $RecoveryKeyResponse.value

                if ($RecoveryKeys) {
                    foreach ($key in $RecoveryKeys) {
                        try {
                            $asPostParams["Body"] = @{
                                    RecoveryKeyId = $Key.RecoveryKeyId                    
                                } | ConvertTo-Json
                            $asPostParams["URI"] = "$($DeviceClassURL)($($CMDevice.MachineId))/AdminService.GetRecoveryKeyValue"
                            $GetRecoveryKeyValueResponse = Invoke-RestMethod @asPostParams
                            $KeyObject = [PSCustomObject]@{
                                ResourceId = $CMDevice.MachineId
                                DeviceName = $CMDevice.Name
                                ItemKey = $key.ItemKey
                                RecoveryKeyId = $key.RecoveryKeyId
                                VolumeTypeId = $key.VolumeTypeId
                                RecoveryKey = if($GetRecoveryKeyValueResponse.value) {$GetRecoveryKeyValueResponse.value} else {$null}
                            }
                            $KeyObject
                        }
                        catch {
                            Throw $_
                        }

                    }
                }
            }
            catch {
                $RecoveryKeys = $null
            }
        }
    #endregion
