New-ItemProperty -Path "HKCU:\Software\Sysinternals\ZoomIt" -Name "EulaAccepted" -Value 1 -PropertyType DWord -Force
New-Item -Path "HKCU:\Software\Microsoft\Windows" -Name "Run" -Force
