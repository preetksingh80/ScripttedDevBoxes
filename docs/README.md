# Installation Scripts - Usage Guide

This project contains PowerShell automation for software install and cleanup using Chocolatey and Winget.

## Project Structure

```text
C:\ScripttedDevBoxes\
  docs\
    README.md
    QUICK_START.md
  manifests\
    INSTALL_MANIFEST.txt
  scripts\
    chocolatey\
      install.ps1
      cleanup.ps1
    winget\
      install.ps1
      cleanup.ps1
  launchers\
    chocolatey\
      run-install.bat
      run-cleanup.bat
    winget\
      run-install.bat
      run-cleanup.bat
  logs\
  output\
```

## Running The Scripts

### Method 1: Use Launchers (recommended)
- Chocolatey install: `C:\ScripttedDevBoxes\launchers\chocolatey\run-install.bat`
- Chocolatey cleanup: `C:\ScripttedDevBoxes\launchers\chocolatey\run-cleanup.bat`
- Winget install: `C:\ScripttedDevBoxes\launchers\winget\run-install.bat`
- Winget cleanup: `C:\ScripttedDevBoxes\launchers\winget\run-cleanup.bat`

### Method 2: Run PowerShell Directly

Chocolatey install:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
& "C:\ScripttedDevBoxes\scripts\chocolatey\install.ps1"
```

Chocolatey cleanup:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
& "C:\ScripttedDevBoxes\scripts\chocolatey\cleanup.ps1"
```

Winget install:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
& "C:\ScripttedDevBoxes\scripts\winget\install.ps1"
```

Winget cleanup:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
& "C:\ScripttedDevBoxes\scripts\winget\cleanup.ps1"
```

## Logging

Runtime logs are still written to `C:\Install_logs\` by the scripts.

## Notes

- `logs\` and `output\` folders are included for project-local artifacts if you later decide to store generated files inside the project.
- Existing script behavior is unchanged; this update is primarily structural and path-focused.
