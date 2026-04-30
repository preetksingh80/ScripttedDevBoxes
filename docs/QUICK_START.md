# Quick Start Guide

## Fastest Path

1. Open `C:\ScripttedDevBoxes\launchers\`.
2. Double-click one of these:
   - `chocolatey\run-install.bat`
   - `winget\run-install.bat`
3. Accept UAC prompt.

## Direct PowerShell Commands

Chocolatey install:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
& "C:\ScripttedDevBoxes\scripts\chocolatey\install.ps1"
```

Winget install:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
& "C:\ScripttedDevBoxes\scripts\winget\install.ps1"
```

Chocolatey cleanup:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
& "C:\ScripttedDevBoxes\scripts\chocolatey\cleanup.ps1"
```

Winget cleanup:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
& "C:\ScripttedDevBoxes\scripts\winget\cleanup.ps1"
```

## Where Files Are

- Scripts: `C:\ScripttedDevBoxes\scripts\...`
- Launchers: `C:\ScripttedDevBoxes\launchers\...`
- Docs: `C:\ScripttedDevBoxes\docs\...`
- Manifest: `C:\ScripttedDevBoxes\manifests\INSTALL_MANIFEST.txt`
- Runtime logs: `C:\Install_logs\`
