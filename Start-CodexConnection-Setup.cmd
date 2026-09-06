@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0CodexConnection\Setup-CodexConnection.ps1" %*
set "setupExitCode=%ERRORLEVEL%"
echo.
if "%setupExitCode%"=="0" (
    echo Setup completed successfully.
) else (
    echo Setup failed. Read the error above and the local setup log.
)
echo Press any key to close this window.
pause >nul
exit /b %setupExitCode%
