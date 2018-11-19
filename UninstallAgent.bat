@ECHO OFF
setLocal ENABLEDELAYEDEXPANSION

CLS
ECHO	�����������������������������������������������������������������������Ŀ
ECHO	�									�
ECHO	�									�
ECHO	�                    UNINSTALL: Removing vRA Agents                     �
ECHO	�									�
ECHO	�									�
ECHO	�������������������������������������������������������������������������
rmdir /s /q !SystemDrive!\hold >nul 2>nul & verify >nul

ECHO Removing any vRA agents installed...
:REMOVEAGENTSVC
ECHO Removing vRA Guest Agent...
net stop vcacguestagentservice >nul 2>nul
sc delete vcacguestagentservice >nul
timeout 3 >nul
rmdir /s /q !SystemDrive!\VRMGuestAgent >nul 2>nul & verify >nul

:REMOVEBOOTSTRAPSVC
ECHO Removing vRA Software Agent...
net stop vRASoftwareAgentBootstrap >nul 2>nul
sc delete vRASoftwareAgentBootstrap >nul
timeout 3 >nul
rmdir /s /q !SystemDrive!\opt >nul 2>nul & verify >nul

:REMOVEACCOUNT
ECHO Removing Darwin Local Service Account...
powershell -noprofile -executionPolicy bypass -command "Remove-LocalUser -Name \"Darwin\" -ErrorAction SilentlyContinue"

:SUCCESS
CLS
ECHO	�����������������������������������������������������������������������Ŀ
ECHO	�									�
ECHO	�                   SUCCESS: vRA Agent removed     	                �
ECHO	�									�
ECHO	�������������������������������������������������������������������������
ECHO Uninstall Complete. Please Reboot System
Choice /T 30 /D Y /M "Would you like to reboot now"
IF !ERRORLEVEL! EQU 1 Shutdown /r /f /t 03 /c "Rebooting system..."
IF !ERRORLEVEL! EQU 2 GOTO EOF
:EOF