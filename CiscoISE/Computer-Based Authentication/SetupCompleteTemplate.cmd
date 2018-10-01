@ECHO OFF

REM SCCMClientPath should be set before we get here

REM This script is written by ConfigMgr Task Sequence Upgrade Operating System action 
REM SetupComplete.cmd -- Upgrade Complete, calling TSMBootstrap to resume task sequence 
echo %DATE%-%TIME% Entering setupcomplete.cmd >> %WINDIR%\setupcomplete.log

echo %DATE%-%TIME% Setting env var _SMSTSSetupRollback=FALSE >> %WINDIR%\setupcomplete.log
set _SMSTSSetupRollback=FALSE

echo %DATE%-%TIME% Setting registry to resume task sequence after reboot >> %WINDIR%\setupcomplete.log
reg add "HKEY_LOCAL_MACHINE\SYSTEM\Setup" /v SetupType /t REG_DWORD /d 2 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\Setup" /v CmdLine /t REG_SZ /d "%WINDIR%\SMSTSPostUpgrade\setupcomplete.cmd" /f

echo %DATE%-%TIME% Running %SCCMClientPath%\TSMBootstrap.exe to resume task sequence >> %WINDIR%\setupcomplete.log
%SCCMClientPath%\TSMBootstrap.exe /env:Gina /configpath:%_SMSTSMDataPath% /bootcount:2 /reloadenv

IF %ERRORLEVEL% EQU -2147021886 (
echo %DATE%-%TIME% ERRORLEVEL = %ERRORLEVEL%  >> %WINDIR%\setupcomplete.log
echo %DATE%-%TIME% TSMBootstrap requested reboot >> %WINDIR%\setupcomplete.log
echo %DATE%-%TIME% Rebooting now >> %WINDIR%\setupcomplete.log
reg add "HKEY_LOCAL_MACHINE\SYSTEM\Setup" /v SetupShutdownRequired /t REG_DWORD /d 1 /f
) else (
echo %DATE%-%TIME% ERRORLEVEL = %ERRORLEVEL%  >> %WINDIR%\setupcomplete.log
echo %DATE%-%TIME% TSMBootstrap did not request reboot, resetting registry >> %WINDIR%\setupcomplete.log
reg add "HKEY_LOCAL_MACHINE\SYSTEM\Setup" /v SetupType /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\Setup" /v CmdLine /t REG_SZ /d "" /f
)
echo %DATE%-%TIME% Exiting setupcomplete.cmd >> %WINDIR%\setupcomplete.log

set SCCMClientPath=