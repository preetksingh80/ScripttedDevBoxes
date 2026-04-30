@echo off
REM Batch file to run Chocolatey Installation Script
REM This file requires Administrator privileges

echo.
echo ==========================================
echo Chocolatey Installation Script Launcher
echo ==========================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires Administrator privileges.
    echo Requesting elevation...
    echo.
    
    REM Re-run as administrator
    powershell -Command "Start-Process cmd -ArgumentList '/c cd /d \"%cd%\" && powershell -NoProfile -ExecutionPolicy Bypass -File \"%~dp0..\..\scripts\chocolatey\install.ps1\"' -Verb RunAs"
    exit /b
)

REM Run the PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\..\scripts\chocolatey\install.ps1"

pause
