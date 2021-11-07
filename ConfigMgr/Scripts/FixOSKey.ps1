$opk = (Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
#$genericWin10Key = "DXG7C-N36C4-C4HTG-X4T3X-2YV77"
$KMS='NPPR9-FWDCX-D2C8J-H872K-2YT43'
$KMSservice = Get-WMIObject -query "select * from SoftwareLicensingService"
Write-Debug 'Activating Windows.'

Get-WmiObject -query 'select * from SoftwareLicensingProduct WHERE PartialProductKey <> null and ApplicationID = "55c92734-d682-4d71-983e-d6ec3f16059f"'

$null = $KMSservice.InstallProductKey($opk)
$null = $KMSservice.RefreshLicenseStatus()

Get-WmiObject -query 'select * from SoftwareLicensingProduct WHERE PartialProductKey <> null and ApplicationID = "55c92734-d682-4d71-983e-d6ec3f16059f"'

$null = $KMSservice.InstallProductKey($KMS)
$null = $KMSservice.RefreshLicenseStatus()

Get-WmiObject -query 'select * from SoftwareLicensingProduct WHERE PartialProductKey <> null and ApplicationID = "55c92734-d682-4d71-983e-d6ec3f16059f"'
