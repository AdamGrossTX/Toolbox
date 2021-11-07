$GlobalLoggingPath = "HKLM:\SOFTWARE\Microsoft\CCM\Logging\@GLOBAL"
$DebugLoggingPath = "HKLM:\SOFTWARE\Microsoft\CCM\Logging\DebugLogging"

New-ItemProperty -Path $GlobalLoggingPath -Name LogLevel -PropertyType DWORD -Value 0 -Force
New-ItemProperty -Path $GlobalLoggingPath -Name LogMaxHistory -PropertyType DWORD -Value 4 -Force
New-ItemProperty -Path $GlobalLoggingPath -Name LogMaxSize -PropertyType DWORD -Value 5242880 -Force
New-Item -Path $DebugLoggingPath -ItemType Directory -Force
New-ItemProperty -Path $DebugLoggingPath -Name Enabled -PropertyType String -Value True -Force

Restart-service ccmexec
