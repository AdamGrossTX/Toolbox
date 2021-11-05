Install-Module -Name PartnerCenter -AllowClobber

#Connect-PartnerCenter

$Customers = Get-PartnerCustomer

$device = New-Object -TypeName Microsoft.Store.PartnerCenter.PowerShell.Models.DevicesDeployment.PSDevice
$device.ModelName = "20UES0EM00"
$device.OemManufacturerName = "LENOVO"
$device.SerialNumber = "XXXXXXX"
$device.DeviceId = "MyTestPO"

$result = New-PartnerCustomerDeviceBatch -BatchId "Test" -CustomerId $Customers[0].CustomerId -Devices $device

$result.DevicesStatus


$Device | select *