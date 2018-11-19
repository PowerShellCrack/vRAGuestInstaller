@echo off
REM
REM Copyright (c) 2013-2015 VMware, Inc. All rights reserved.
REM
REM Description:
REM   VMware vRealize Automation Software Service Agent and Guest VRM Agent removal script.
REM     * Remove darwin user.
REM     * Remove Software Service Agent.
REM     * Remove Guest VRM Agent
REM

echo VMware vRealize Automation Software Service Agent and Guest VRM Agent removal script.
echo.
echo    * Remove darwin user.
echo    * Remove Software Service Agent.
echo    * Remove Guest VRM Agent

set VCAC_AGENT_SERVICE=VCACGuestAgentService
set VCAC_AGENT_INSTALLATION_DIRECTORY=%SystemDrive%\opt\vmware-vcac-agent
set APPD_AGENT_SERVICE=vRASoftwareAgentBootstrap
set APPD_AGENT_INSTALLATION_DIRECTORY=%SystemDrive%\opt\vmware-appdirector

REM Uninstall vCAC agent service.
CALL :UninstallAgent %VCAC_AGENT_SERVICE% %VCAC_AGENT_INSTALLATION_DIRECTORY% false

REM Uninstall Application Director agent service.
CALL :UninstallAgent %APPD_AGENT_SERVICE% %APPD_AGENT_INSTALLATION_DIRECTORY% true

echo.
echo Delete Darwin user.
echo.

REM Delete darwin user.
net user darwin /DELETE

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Deletion of darwin user failed, delete darwin user and darwin user data manually.
) else (
    echo darwin user delete successfully!
    echo.

    echo Deleting darwin user data
    echo.

    REM Delete darwin user data
    rd /q /s C:\Users\darwin

    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Deletion of darwin user data failed, delete darwin user data directory manually "C:\Users\darwin".
    ) else (
        echo darwin user data directory "C:\Users\darwin" deleted successfully!
    )
)

REM End.
goto :eof

REM Following function uninstalls a given service
REM     param1: Service Name as seen in service control manager.
REM     param2: Installation Directory of the service.
REM     param3: Whether to delete the directory post uninstall.

:UninstallAgent
REM Check if agent service is installed and running.
for /F "tokens=3 delims=: " %%H in ('sc query "%1" ^| findstr "        STATE"') do (
    if "%%H" == "RUNNING" (

        REM Found service in running mode now stop it.
        echo Stopping %1 agent service.
        echo.

        REM Stop service
        net stop %1

        if %ERRORLEVEL% NEQ 0 (
            echo Error: %1 agent service could not be stopped.
            echo Please go ahead and stop the service manually and retry running the script again.
            echo.
            goto :eof
        )

        echo %1 agent service stopped successfully
        echo.
    ) else (
        echo %1 agent service already in stopped state
        echo.
    )
)


REM Delete service from SCM.
sc delete %1

if %ERRORLEVEL% NEQ 0 (
    echo Error: %1 agent service could not be uninstalled.
    echo Manually run "sc delete %1" and delete installation directory %2.
    echo.
) else (
    echo %1 agent service uninstalled successfully
    echo.

    REM Check to see if need to delete installation directory.
    if %3 EQU true (
        echo Deleting %1 agent service installation directory %2.
        echo.

        REM Delete %1 agent installation directory.
        rd /q /s %2

        if %ERRORLEVEL% NEQ 0 (
            echo Error: Unable to delete %2 directory, go ahead and delete it manually.
            echo.
        ) else (
            echo %1 agent removed successfully!
            echo.
        )
    )
)
:eof
