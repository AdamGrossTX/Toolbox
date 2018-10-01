REM this line will fail in PE but is needed in Windows
REM set the Wired AutoConfig service to automatically start
sc config "dot3svc" start= auto >> %~dp0ImportComputerAuthProfile.log

REM start the Wired AutoConfig service
Net Start dot3svc >> %~dp0ImportComputerAuthProfile.log

REM Import Root certificate
certutil.exe -addstore Root "%~dp0Certs\root.cer" >> %~dp0ImportComputerAuthProfile.log

REM Import Computer Certificate
certutil.exe -ImportPFX -f -p P@ssword "%~dp0Certs\ComputerAuthCert.pfx" >> %~dp0ImportComputerAuthProfile.log

REM Import Computer Auth Profile to all LAN interfaces
netsh lan add profile filename="%~dp0ComputerAuthProfile.xml" interface=* >> %~dp0ImportComputerAuthProfile.log

REM Force all interfaces to reconnect
netsh lan reconnect interface=* >> %~dp0ImportComputerAuthProfile.log

REM change the interface name to match your interface name(s). We have 2 in our environment.
REM Disable then Enable the adapter named Ethernet
netsh interface set interface name="ethernet" admin=DISABLED >> %~dp0ImportComputerAuthProfile.log
netsh interface set interface name="ethernet" admin=ENABLED >> %~dp0ImportComputerAuthProfile.log

REM Disable then Enable the adapter named Local Area Connection
netsh interface set interface name="Local Area Connection" admin=DISABLED >> %~dp0ImportComputerAuthProfile.log
netsh interface set interface name="Local Area Connection" admin=ENABLED >> %~dp0ImportComputerAuthProfile.log

REM Pause the script for 30 seconds to allow the adapter to Auth
ping localhost -n 30 >> %~dp0ImportComputerAuthProfile.log

REM Show the interface to see the status and show profiles to see which profile is applied.
netsh lan show interfaces >> %~dp0ImportComputerAuthProfile.log
netsh lan show profiles >> %~dp0ImportComputerAuthProfile.log