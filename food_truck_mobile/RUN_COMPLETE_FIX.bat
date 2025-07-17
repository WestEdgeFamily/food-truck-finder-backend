@echo off
echo Running Complete Fix Script...
echo.

:: Check if PowerShell execution is allowed
powershell -Command "Get-ExecutionPolicy" >nul 2>&1
if errorlevel 1 (
    echo ERROR: PowerShell is not available!
    pause
    exit /b 1
)

:: Run the PowerShell script with bypass execution policy
powershell -ExecutionPolicy Bypass -File "COMPLETE_FIX_AND_BUILD.ps1"

pause