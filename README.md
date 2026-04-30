# ScripttedDevBoxes

Windows automation scripts for software install and cleanup using Chocolatey and Winget.

## Overview

This repository provides:
- PowerShell install and cleanup flows for Chocolatey and Winget.
- Batch launchers for one-click execution with elevation prompts.
- Documentation and a manifest for quick onboarding.

## Repository Layout

```text
ScripttedDevBoxes/
  docs/
    README.md
    QUICK_START.md
  manifests/
    INSTALL_MANIFEST.txt
  scripts/
    chocolatey/
      install.ps1
      cleanup.ps1
    winget/
      install.ps1
      cleanup.ps1
  launchers/
    chocolatey/
      run-install.bat
      run-cleanup.bat
    winget/
      run-install.bat
      run-cleanup.bat
  logs/
  output/
```

## Run

Preferred: run one of the launcher files in `launchers/`.

PowerShell direct examples:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
& ".\\scripts\\chocolatey\\install.ps1"
```

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
& ".\\scripts\\winget\\install.ps1"
```

## Logs

Runtime script logs are written to `C:\Install_logs\`.

## Documentation

- Detailed guide: `docs/README.md`
- Quick start: `docs/QUICK_START.md`
- Manifest: `manifests/INSTALL_MANIFEST.txt`
