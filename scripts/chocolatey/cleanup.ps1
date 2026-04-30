# Chocolatey Cleanup/Uninstall Script
# This script uninstalls all software that was installed via Chocolatey with logging and verification

param(
    [switch]$Force
)

# ============================================================================
# INITIALIZE LOGGING AND LOG FOLDER
# ============================================================================
$LogFolder = "C:\Install_logs"
if (-not (Test-Path $LogFolder)) {
    New-Item -ItemType Directory -Path $LogFolder | Out-Null
}

$LogFile = Join-Path $LogFolder "Chocolatey-Cleanup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$ErrorLogFile = Join-Path $LogFolder "Chocolatey-Cleanup-Errors-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Function to write logs
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'ERROR', 'SUCCESS', 'WARNING')]
        [string]$Level = 'INFO'
    )
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    Write-Host $LogMessage -ForegroundColor $(
        switch ($Level) {
            'INFO'    { 'Cyan' }
            'SUCCESS' { 'Green' }
            'WARNING' { 'Yellow' }
            'ERROR'   { 'Red' }
        }
    )
    
    Add-Content -Path $LogFile -Value $LogMessage
    
    if ($Level -eq 'ERROR') {
        Add-Content -Path $ErrorLogFile -Value $LogMessage
    }
}

# ============================================================================
# CHECK FOR ADMIN PRIVILEGES
# ============================================================================
function Test-AdminPrivileges {
    $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($CurrentUser)
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-AdminPrivileges)) {
    Write-Log "This script requires administrator privileges. Restarting with elevated permissions..." "WARNING"
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Force:$Force" -Verb RunAs
    exit
}

Write-Log "Script started with admin privileges" "SUCCESS"

# ============================================================================
# CHECK IF CHOCOLATEY IS INSTALLED
# ============================================================================
function Test-ChocoInstalled {
    $ChocoPath = "C:\ProgramData\chocolatey\bin\choco.exe"
    if (Test-Path $ChocoPath) {
        Write-Log "Chocolatey is installed" "SUCCESS"
        return $true
    }
    else {
        Write-Log "Chocolatey is not installed" "ERROR"
        return $false
    }
}

if (-not (Test-ChocoInstalled)) {
    Write-Log "Cannot proceed - Chocolatey is not installed" "ERROR"
    Write-Host "`nChocolatey is not installed on this system. Cleanup cannot proceed." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# ============================================================================
# UNINSTALLATION FUNCTION
# ============================================================================
function Uninstall-Software {
    param(
        [string]$PackageName,
        [string]$DisplayName
    )
    
    Write-Log "Uninstalling $DisplayName" "INFO"
    try {
        choco uninstall $PackageName -y 2>&1 | ForEach-Object { Add-Content -Path $LogFile -Value $_ }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Successfully uninstalled $DisplayName" "SUCCESS"
            return $true
        }
        else {
            Write-Log "Failed to uninstall $DisplayName (Exit Code: $LASTEXITCODE)" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Error uninstalling $DisplayName : $_" "ERROR"
        return $false
    }
}

# ============================================================================
# USER CONFIRMATION
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "WARNING: This script will uninstall ALL software installed via Chocolatey" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Yellow
$Confirmation = Read-Host "`nDo you want to continue? (yes/no)"

if ($Confirmation -ne "yes") {
    Write-Log "Cleanup cancelled by user" "WARNING"
    Write-Host "Cleanup cancelled." -ForegroundColor Yellow
    exit
}

# ============================================================================
# UNINSTALL SOFTWARE
# ============================================================================
Write-Log "===========================================" "INFO"
Write-Log "Starting Chocolatey software uninstall" "INFO"
Write-Log "===========================================" "INFO"

# First, uninstall npm global packages
Write-Log "Uninstalling NPM global packages..." "INFO"

try {
    # GitHub Copilot CLI
    Write-Log "Removing GitHub Copilot CLI" "INFO"
    if (Get-Command gh.exe -ErrorAction SilentlyContinue) {
        $ExistingGhExtensions = gh extension list 2>$null
        if ($ExistingGhExtensions -match "github/gh-copilot") {
            gh extension remove github/gh-copilot 2>&1 | ForEach-Object { Add-Content -Path $LogFile -Value $_ }
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Successfully removed GitHub Copilot CLI extension" "SUCCESS"
            }
            else {
                Write-Log "Failed to remove GitHub Copilot CLI extension (Exit Code: $LASTEXITCODE)" "ERROR"
            }
        }
        else {
            Write-Log "GitHub Copilot CLI extension is not installed" "INFO"
        }
    }
    else {
        Write-Log "GitHub CLI is not installed; skipping GitHub Copilot CLI extension cleanup" "INFO"
    }
}
catch {
    Write-Log "Error removing GitHub Copilot CLI: $_" "ERROR"
}

try {
    # Gemini CLI
    Write-Log "Removing Gemini CLI" "INFO"
    npm uninstall -g @google/gemini-cli 2>&1 | ForEach-Object { Add-Content -Path $LogFile -Value $_ }
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Successfully removed Gemini CLI" "SUCCESS"
    }
}
catch {
    Write-Log "Error removing Gemini CLI: $_" "ERROR"
}

try {
    # TypeScript
    Write-Log "Removing TypeScript" "INFO"
    npm uninstall -g typescript 2>&1 | ForEach-Object { Add-Content -Path $LogFile -Value $_ }
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Successfully removed TypeScript" "SUCCESS"
    }
}
catch {
    Write-Log "Error removing TypeScript: $_" "ERROR"
}

# Browsers and Drivers
Uninstall-Software -PackageName "googlechrome" -DisplayName "Google Chrome browser"
Uninstall-Software -PackageName "chromedriver" -DisplayName "Google Chrome Driver"

# Development Tools
Uninstall-Software -PackageName "git" -DisplayName "GIT"
Uninstall-Software -PackageName "github-desktop" -DisplayName "GitHub Desktop"
Uninstall-Software -PackageName "gh" -DisplayName "GitHub CLI"
Uninstall-Software -PackageName "nodejs" -DisplayName "Node.js"
Uninstall-Software -PackageName "python" -DisplayName "Python"
Uninstall-Software -PackageName "dotnet-9.0-sdk" -DisplayName "Microsoft .NET SDK 9"
Uninstall-Software -PackageName "dotnet-8.0-sdk" -DisplayName "Microsoft .NET SDK 8 (Core/LTS)"

# Docker
Uninstall-Software -PackageName "docker-desktop" -DisplayName "Docker Desktop"

# IDE and Editor
Uninstall-Software -PackageName "vscode" -DisplayName "Visual Studio Code"

# CLI Tools and Utilities
Uninstall-Software -PackageName "7zip" -DisplayName "7Zip"
Uninstall-Software -PackageName "notepadplusplus" -DisplayName "Notepad++"
Uninstall-Software -PackageName "sqlite" -DisplayName "SQLite"
Uninstall-Software -PackageName "sql-server-management-studio" -DisplayName "SQL Server Management Studio"

# ============================================================================
# FINAL LOGGING
# ============================================================================
Write-Log "===========================================" "INFO"
Write-Log "Chocolatey cleanup script completed" "SUCCESS"
Write-Log "===========================================" "INFO"
Write-Log "Logs saved to: $LogFile" "INFO"

if ((Test-Path $ErrorLogFile) -and ((Get-Item -Path $ErrorLogFile).Length -gt 0)) {
    Write-Log "Errors logged to: $ErrorLogFile" "WARNING"
}

Write-Host "`nCleanup complete! Logs are available at:`n  $LogFile" -ForegroundColor Green
Read-Host "Press Enter to exit"
