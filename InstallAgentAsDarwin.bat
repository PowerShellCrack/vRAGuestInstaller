@ECHO OFF
setLocal ENABLEDELAYEDEXPANSION
SET VRAHOST=<vra app>.<fqdn>
SET VRAMGR=<vra mgr>.<fqdn>
SET APPCERTPRINT=<app cert thumbprint>
SET MGRCERTPRINT=<mgr cert thumbprint>
SET DARWINUSER=.\Darwin

CLS
ECHO	ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
ECHO	³									³
ECHO	³									³
ECHO	³                    PREPARE: vRA Agent with Darwin                     ³
ECHO	³									³
ECHO	³									³
ECHO	ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
ECHO.
SET /P DARWINPASSWORD=What is Darwin's Password? 

rmdir /s /q !SystemDrive!\hold >nul 2>nul & verify >nul

ECHO Removing any vRA agents installed...
:REMOVEAGENTSVC
ECHO Removing vRA Guest Agent...
net stop vcacguestagentservice >nul 2>nul
sc delete vcacguestagentservice >nul

:REMOVEBOOTSTRAPSVC
ECHO Removing vRA Software Agent...
net stop vRASoftwareAgentBootstrap >nul 2>nul
sc delete vRASoftwareAgentBootstrap >nul
rmdir /s /q !SystemDrive!\opt >nul 2>nul & verify >nul
timeout 3 >nul

:REMOVEACCOUNT
ECHO Cleaning up !DARWINUSER!'s profile folder(s) if exist...
powershell -noprofile -executionPolicy bypass -File "%~dp0scripts\Cleanup-Profile.ps1" -Name "!DARWINUSER!"

:BUILDACCOUNT
ECHO Building !DARWINUSER! Local Service Account...
powershell.exe -noprofile -executionPolicy bypass -file "%~dp0scripts\Set-LocalAccount.ps1" -Username "!DARWINUSER!" -Password "!DARWINPASSWORD!" -Description "vRA Guest Agent Local Service Account"
If !ERRORLEVEL! NEQ 0 GOTO ERROR
timeout 3 >nul

:INSTALLAGENT
CLS
ECHO	ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
ECHO	³									³
ECHO	³									³
ECHO	³                    READY: vRA Agent with Darwin                       ³
ECHO	³									³
ECHO	³									³
ECHO	ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
ECHO    Installing vRA Agent...
powershell.exe -noprofile -executionPolicy bypass -file "%~dp0scripts\prepare_vra_template.ps1" -ApplianceHost !VRAHOST! -ManagerServiceHost !VRAMGR! -CloudProvider vSphere -SoftwareDomainUser !DARWINUSER! -SoftwarePassword !DARWINPASSWORD! -ManagerFingerprint !MGRCERTPRINT! -ApplianceFingerprint !APPCERTPRINT! -Noninteractive -NoWindowsCheck
If !ERRORLEVEL! NEQ 0 GOTO ERROR
GOTO SCRIPTS

:SCRIPTS
REM Adding custom scripts...
mkdir c:\VRMGuestAgent\scripts
copy %~dp0scripts\UserandGroupControl.vbs c:\VRMGuestAgent\scripts\UserandGroupControl.vbs
If !ERRORLEVEL! NEQ 0 GOTO ERROR
GOTO SUCCESS

:ERROR
ECHO	ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
ECHO	³									³
ECHO	³                   ERROR: vRA Agent install failed	                ³
ECHO	³									³
ECHO	ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
ECHO Agent was unable to install. Agent may be already installed, Follow README.txt and uninstalling the agent and reboot. 
pause
GOTO EOF

:SUCCESS
ECHO	ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
ECHO	³									³
ECHO	³                   SUCCESS: vRA Agent installed     	                ³
ECHO	³									³
ECHO	ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
ECHO Install Complete. Shutdown and convert to template
Choice /T 30 /D Y /M "Would you like to shutdown now"
IF !ERRORLEVEL! EQU 1 GOTO SHUTDOWN
IF !ERRORLEVEL! EQU 2 GOTO EOF


:SHUTDOWN
SET InstallDIR=!cd!
REM Removing the script folder (!InstallDIR!) and preparing to shutdown
cd\
cmd /c "Taskkill /f /im explorer.exe && start explorer.exe" >nul 2>nul & verify >nul
start /b "" cmd /c rmdir /s /q "!InstallDIR!" && Shutdown /s /t 05 /c "Shutting down system..." >nul 2>nul & verify >nul




:EOF