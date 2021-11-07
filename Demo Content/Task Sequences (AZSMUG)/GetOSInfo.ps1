C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -Command "& {

$OS = Get-CimInstance Win32_OperatingSystem; 
$OSCaption = $OS.Caption; 
$OSVersion = $OS.Version; 
$OSBuild = $OS.buildNumber; 
$OSArchitecture = $OS.OSArchitecture;

$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment; 
$tsenv.Value('OSCaption') = $OSCaption; 
$tsenv.Value('OSVersion') = $OSVersion; 
$tsenv.Value('OSBuild') = $OSBuild; 
$tsenv.Value('OSArchitecture') = $OSArchitecture; 
Write-Host Getting TS Variables; 
Write-Host OSCaption: $tsenv.Value('OSCaption'); 
Write-Host OSVersion: $tsenv.Value('OSVersion'); 
Write-Console OSBuild: $tsenv.Value('OSBuild'); 
Write-Host OSArchitecture: $tsenv.Value('OSArchitecture')


}"