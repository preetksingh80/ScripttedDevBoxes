# Winget Cleanup/Uninstall Script
# This script uninstalls all software that was installed via Winget with logging and verification

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

$LogFile = Join-Path $LogFolder "Winget-Cleanup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$ErrorLogFile = Join-Path $LogFolder "Winget-Cleanup-Errors-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

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
# CHECK IF WINGET IS INSTALLED
# ============================================================================
function Test-WingetInstalled {
    try {
        $WingetVersion = winget --version 2>$null
        if ($WingetVersion) {
            Write-Log "Winget is installed. Version: $WingetVersion" "SUCCESS"
            return $true
        }
    }
    catch {}
    
    Write-Log "Winget is not installed or not available" "ERROR"
    return $false
}

if (-not (Test-WingetInstalled)) {
    Write-Log "Cannot proceed - Winget is not installed" "ERROR"
    Write-Host "`nWindows Package Manager (Winget) is not installed on this system. Cleanup cannot proceed." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# ============================================================================
# UNINSTALLATION FUNCTION FOR WINGET
# ============================================================================
function Uninstall-Software {
    param(
        [string]$PackageId,
        [string]$DisplayName
    )
    
    Write-Log "Uninstalling $DisplayName" "INFO"
    try {
        winget uninstall --id $PackageId -e --accept-source-agreements -y 2>&1 | ForEach-Object { Add-Content -Path $LogFile -Value $_ }
        
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
Write-Host "WARNING: This script will uninstall ALL software installed via Winget" -ForegroundColor Red
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
Write-Log "Starting Winget software uninstall" "INFO"
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
Uninstall-Software -PackageId "Google.Chrome" -DisplayName "Google Chrome browser"
Uninstall-Software -PackageId "Google.ChromeDriver" -DisplayName "Google Chrome Driver"

# Development Tools
Uninstall-Software -PackageId "Git.Git" -DisplayName "GIT"
Uninstall-Software -PackageId "GitHub.GitHubDesktop" -DisplayName "GitHub Desktop"
Uninstall-Software -PackageId "GitHub.cli" -DisplayName "GitHub CLI"
Uninstall-Software -PackageId "OpenJS.NodeJS.LTS" -DisplayName "Node.js"
Uninstall-Software -PackageId "Python.Python.3" -DisplayName "Python"
Uninstall-Software -PackageId "Microsoft.DotNet.SDK.9" -DisplayName "Microsoft .NET SDK 9"
Uninstall-Software -PackageId "Microsoft.DotNet.SDK.8" -DisplayName "Microsoft .NET SDK 8 (Core/LTS)"

# Docker
Uninstall-Software -PackageId "Docker.DockerDesktop" -DisplayName "Docker Desktop"

# IDE and Editor
Uninstall-Software -PackageId "Microsoft.VisualStudioCode" -DisplayName "Visual Studio Code"

# CLI Tools and Utilities
Uninstall-Software -PackageId "7zip.7zip" -DisplayName "7Zip"
Uninstall-Software -PackageId "Notepad++.Notepad++" -DisplayName "Notepad++"
Uninstall-Software -PackageId "SQLite.SQLite" -DisplayName "SQLite"
Uninstall-Software -PackageId "Microsoft.SQLServerManagementStudio" -DisplayName "SQL Server Management Studio"

# ============================================================================
# FINAL LOGGING
# ============================================================================
Write-Log "===========================================" "INFO"
Write-Log "Winget cleanup script completed" "SUCCESS"
Write-Log "===========================================" "INFO"
Write-Log "Logs saved to: $LogFile" "INFO"

if ((Test-Path $ErrorLogFile) -and ((Get-Item -Path $ErrorLogFile).Length -gt 0)) {
    Write-Log "Errors logged to: $ErrorLogFile" "WARNING"
}

Write-Host "`nCleanup complete! Logs are available at:`n  $LogFile" -ForegroundColor Green
Read-Host "Press Enter to exit"
