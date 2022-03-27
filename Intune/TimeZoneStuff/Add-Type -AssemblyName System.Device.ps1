Add-Type -AssemblyName System.Device
$gw = New-Object System.Device.Location.GeoCoordinateWatcher
$gw.Start()
$gw.Permission

$gw.stop()