@ECHO OFF
setLocal ENABLEDELAYEDEXPANSION
SET FQDN=<fqdn>
SET WSUSSVR=%1
SET DOMAINWSUSSVR=http://<wsus name>.<fqdn>:<wsus port>
IF "%1" EQU "" SET WSUSSVR=!DOMAINWSUSSVR!
If "!DOMAINWSUSSVR!" EQU "" SET /P WSUSSVR=Whats the wsus server url or IP and Port [eg. http://wsus.!FQDN!:8530]?

:PSVERSION
for /f "skip=3 tokens=2 delims=:" %%A in ('powershell -noprofile -executionPolicy bypass -command "get-host"') do (
	set /a n=!n!+1
	set c=%%A
	if !n!==1 set PSVersion=!c!
)
Set PSVersion=%PSVersion: =%

IF !PSVersion! LSS 5.1 GOTO UPDATEPS
GOTO UPDATES

:UPDATEPS
CLS
ECHO	ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
ECHO	³									³
ECHO	³									³
ECHO	³                     POWERSHELL: Updating to 5.1                       ³
ECHO	³									³
ECHO	³									³
ECHO	ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
ECHO.
ECHO Powershell is out-of-date, current version is: !PSVersion!
powershell.exe -noprofile -executionPolicy bypass -file "%~dp0scripts\Install-WMF5.1.ps1" -UpdatesPath "%~dp0scripts\Updates" -AcceptEULA -AllowRestart

:UPDATES
CLS
ECHO	ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
ECHO	³									³
ECHO	³									³
ECHO	³                    PREPARE: Checking for Updates                      ³
ECHO	³									³
ECHO	³									³
ECHO	ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
ECHO.
ECHO Configuring time...
powershell.exe -noprofile -executionPolicy bypass -file "%~dp0Scripts\Set-TimeZone.ps1" -TimeZone "Eastern Standard Time"

ECHO Configuring system's WSUS policy to use !WSUSSVR!
ECHO ; PROCESSING WSUS POLICY > %~dp0\scripts\wsus.lgpo
ECHO ; -------------------------------------------------------->> %~dp0\scripts\wsus.lgpo
ECHO Computer>> %~dp0\scripts\wsus.lgpo
ECHO Software\Policies\Microsoft\Windows\WindowsUpdate\AU>> %~dp0\scripts\wsus.lgpo
ECHO UseWUServer>> %~dp0\scripts\wsus.lgpo
ECHO DWORD:1>> %~dp0\scripts\wsus.lgpo
ECHO.>> %~dp0\scripts\wsus.lgpo
ECHO Computer>> %~dp0\scripts\wsus.lgpo
ECHO Software\Policies\Microsoft\Windows\WindowsUpdate>> %~dp0\scripts\wsus.lgpo
ECHO WUServer>> %~dp0\scripts\wsus.lgpo
ECHO SZ:!WSUSSVR!>> %~dp0\scripts\wsus.lgpo
ECHO.>> %~dp0\scripts\wsus.lgpo
ECHO Computer>> %~dp0\scripts\wsus.lgpo
ECHO Software\Policies\Microsoft\Windows\WindowsUpdate>> %~dp0\scripts\wsus.lgpo
ECHO WUStatusServer>> %~dp0\scripts\wsus.lgpo
ECHO SZ:!WSUSSVR!>> %~dp0\scripts\wsus.lgpo
ECHO.>> %~dp0\scripts\wsus.lgpo
ECHO Computer>> %~dp0\scripts\wsus.lgpo
ECHO Software\Policies\Microsoft\Windows\WindowsUpdate>> %~dp0\scripts\wsus.lgpo
ECHO DisableOSUpgrade>> %~dp0\scripts\wsus.lgpo
ECHO DWORD:1>> %~dp0\scripts\wsus.lgpo
ECHO.>> %~dp0\scripts\wsus.lgpo
ECHO Computer>> %~dp0\scripts\wsus.lgpo
ECHO Software\Policies\Microsoft\Windows\WindowsUpdate>> %~dp0\scripts\wsus.lgpo
ECHO DoNotConnectToWindowsUpdateInternetLocations>> %~dp0\scripts\wsus.lgpo
ECHO DWORD:1>> %~dp0\scripts\wsus.lgpo
ECHO.>> %~dp0\scripts\wsus.lgpo
ECHO Computer>> %~dp0\scripts\wsus.lgpo
ECHO Software\Policies\Microsoft\Windows\WindowsUpdate>> %~dp0\scripts\wsus.lgpo
ECHO ManagePreviewBuilds>> %~dp0\scripts\wsus.lgpo
ECHO DWORD:1>> %~dp0\scripts\wsus.lgpo
ECHO.>> %~dp0\scripts\wsus.lgpo
ECHO Computer>> %~dp0\scripts\wsus.lgpo
ECHO Software\Policies\Microsoft\Windows\WindowsUpdate>> %~dp0\scripts\wsus.lgpo
ECHO ManagePreviewBuildsPolicyValue>> %~dp0\scripts\wsus.lgpo
ECHO DWORD:0>> %~dp0\scripts\wsus.lgpo

ECHO Applying WSUS Policy...
%~dp0\scripts\LGPO.exe /t %~dp0\scripts\wsus.lgpo
timeout 3
ECHO Restarting WSUS Services...
net stop wuauserv >nul 2>nul
net start wuauserv >nul 2>nul

ECHO Checking for Windows updates...a reboot may be required
powershell.exe -noprofile -executionPolicy bypass -file "%~dp0scripts\WSUS.ps1" -Install -Reboot

timeout 30
exit