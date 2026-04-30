# Chocolatey Installation Script
# This script installs software via Chocolatey with admin checks, software verification, and logging

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

$LogFile = Join-Path $LogFolder "Chocolatey-Install-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$ErrorLogFile = Join-Path $LogFolder "Chocolatey-Install-Errors-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

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
# SET EXECUTION POLICY FOR CHOCOLATEY
# ============================================================================
try {
    Write-Log "Setting PowerShell execution policy to Bypass for Chocolatey..." "INFO"
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force -ErrorAction Stop
    Write-Log "Execution policy set successfully" "SUCCESS"
}
catch {
    Write-Log "Failed to set execution policy: $_" "ERROR"
}

# ============================================================================
# CHECK IF CHOCOLATEY IS INSTALLED
# ============================================================================
function Test-ChocoInstalled {
    $ChocoPath = "C:\ProgramData\chocolatey\bin\choco.exe"
    if (Test-Path $ChocoPath) {
        Write-Log "Chocolatey is installed at: $ChocoPath" "SUCCESS"
        return $true
    }
    else {
        Write-Log "Chocolatey is not installed" "WARNING"
        return $false
    }
}

if (-not (Test-ChocoInstalled)) {
    Write-Log "Installing Chocolatey..." "INFO"
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Log "Chocolatey installed successfully" "SUCCESS"
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    }
    catch {
        Write-Log "Failed to install Chocolatey: $_" "ERROR"
        exit 1
    }
}

# ============================================================================
# FUNCTION TO CHECK IF SOFTWARE IS INSTALLED
# ============================================================================
function Test-SoftwareInstalled {
    param(
        [string]$PackageName,
        [string]$DisplayName
    )
    
    try {
        $ChocoList = choco list --local-only --exact $PackageName 2>$null
        if ($ChocoList -match "^$([regex]::Escape($PackageName))\s") {
            Write-Log "$DisplayName is already installed" "INFO"
            return $true
        }
    }
    catch {}
    
    return $false
}

# ============================================================================
# INSTALLATION FUNCTION
# ============================================================================
function Install-Software {
    param(
        [string]$PackageName,
        [string]$DisplayName,
        [string]$AdditionalArgs = ""
    )
    
    if (Test-SoftwareInstalled -PackageName $PackageName -DisplayName $DisplayName) {
        Write-Log "Skipping $DisplayName (already installed)" "INFO"
        return $true
    }
    
    Write-Host "Installing $DisplayName"
    Write-Log "Installing $DisplayName" "INFO"
    try {
        if ($AdditionalArgs) {
            choco install $PackageName -y --limit-output --no-progress $AdditionalArgs.Split() 2>&1 | ForEach-Object { Add-Content -Path $LogFile -Value $_ }
        }
        else {
            choco install $PackageName -y --limit-output --no-progress 2>&1 | ForEach-Object { Add-Content -Path $LogFile -Value $_ }
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Successfully installed $DisplayName" "SUCCESS"
            return $true
        }
        else {
            Write-Log "Failed to install $DisplayName (Exit Code: $LASTEXITCODE)" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Error installing $DisplayName : $_" "ERROR"
        return $false
    }
}

# ============================================================================
# INSTALL SOFTWARE
# ============================================================================
Write-Log "==========================================" "INFO"
Write-Log "Starting Chocolatey software installation" "INFO"
Write-Log "==========================================" "INFO"

# Browsers and Drivers
Install-Software -PackageName "googlechrome" -DisplayName "Google Chrome browser" -AdditionalArgs "--ignore-checksums"
Install-Software -PackageName "chromedriver" -DisplayName "Google Chrome Driver" -AdditionalArgs "--ignore-checksums"

# Development Tools
Install-Software -PackageName "git" -DisplayName "GIT"
Install-Software -PackageName "github-desktop" -DisplayName "GitHub Desktop"
Install-Software -PackageName "gh" -DisplayName "GitHub CLI"
Install-Software -PackageName "nodejs" -DisplayName "Node.js"
Install-Software -PackageName "python" -DisplayName "Python latest"
Install-Software -PackageName "dotnet-9.0-sdk" -DisplayName "Microsoft .NET SDK 9"
Install-Software -PackageName "dotnet-8.0-sdk" -DisplayName "Microsoft .NET SDK 8 (Core/LTS)"

# Docker
Install-Software -PackageName "docker-desktop" -DisplayName "Docker Desktop"

# IDE and Editor
Install-Software -PackageName "vscode" -DisplayName "Visual Studio Code"

# CLI Tools and Utilities
Install-Software -PackageName "7zip" -DisplayName "7Zip"
Install-Software -PackageName "notepadplusplus" -DisplayName "Notepad++"
Install-Software -PackageName "sqlite" -DisplayName "SQLite"
Install-Software -PackageName "sql-server-management-studio" -DisplayName "SQL Server Management Studio"

# ============================================================================
# INSTALL CLI TOOLS VIA NPM (Node Package Manager)
# ============================================================================
Write-Log "Installing CLI tools via NPM..." "INFO"

try {
    # Wait for Node.js to be available
    $NodePath = "C:\Program Files\nodejs\npm.cmd"
    $MaxRetries = 5
    $Retry = 0
    
    while ((-not (Test-Path $NodePath)) -and ($Retry -lt $MaxRetries)) {
        Write-Log "Waiting for npm to be available... (Attempt $($Retry + 1)/$MaxRetries)" "WARNING"
        Start-Sleep -Seconds 3
        $Retry++
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    }
}
catch {}

if (-not (Get-Command npm.cmd -ErrorAction SilentlyContinue)) {
    Write-Log "npm is not available after Node.js installation; skipping npm-based tools" "ERROR"
}
else {
    if (Get-Command tsc.cmd -ErrorAction SilentlyContinue) {
        Write-Log "TypeScript is already available in PATH" "INFO"
    }
    else {
        Write-Host "Installing TypeScript"
        Write-Log "Installing TypeScript" "INFO"
        npm install -g typescript 2>&1 | ForEach-Object { Add-Content -Path $LogFile -Value $_ }
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Successfully installed TypeScript" "SUCCESS"
        }
        else {
            Write-Log "Failed to install TypeScript (Exit Code: $LASTEXITCODE)" "ERROR"
        }
    }

    if (Get-Command gh.exe -ErrorAction SilentlyContinue) {
        $ExistingGhExtensions = gh extension list 2>$null
        if ($ExistingGhExtensions -match "github/gh-copilot") {
            Write-Log "GitHub Copilot CLI extension already installed" "INFO"
        }
        else {
            Write-Host "Installing GitHub Copilot CLI"
            Write-Log "Installing GitHub Copilot CLI via gh extension" "INFO"
            gh extension install github/gh-copilot 2>&1 | ForEach-Object { Add-Content -Path $LogFile -Value $_ }
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Successfully installed GitHub Copilot CLI extension" "SUCCESS"
            }
            else {
                Write-Log "Failed to install GitHub Copilot CLI extension (Exit Code: $LASTEXITCODE)" "ERROR"
            }
        }
    }
    else {
        Write-Log "GitHub CLI is not available, cannot install GitHub Copilot CLI extension" "ERROR"
    }

    $GeminiInstalled = npm list -g --depth=0 @google/gemini-cli 2>$null
    if ($GeminiInstalled -match "@google/gemini-cli") {
        Write-Log "Gemini CLI is already installed" "INFO"
    }
    else {
        Write-Host "Installing Gemini CLI"
        Write-Log "Installing Gemini CLI" "INFO"
        npm install -g @google/gemini-cli 2>&1 | ForEach-Object { Add-Content -Path $LogFile -Value $_ }
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Successfully installed Gemini CLI" "SUCCESS"
        }
        else {
            Write-Log "Failed to install Gemini CLI (Exit Code: $LASTEXITCODE)" "ERROR"
        }
    }
}

# ============================================================================
# INSTALL VS CODE EXTENSIONS
# ============================================================================
Write-Log "Installing Visual Studio Code extensions..." "INFO"

$VSCodeExtensions = @(
    "ms-python.python",                      # Python
    "ms-dotnettools.csharp",                 # .NET
    "ms-vscode.vscode-typescript-next",      # TypeScript/JavaScript
    "dbaeumer.vscode-eslint",                # JavaScript linting
    "christian-kohler.npm-intellisense",     # Node.js development
    "github.copilot",                        # GitHub Copilot
    "github.copilot-chat",                   # GitHub Copilot Chat
    "googlecloudtools.cloudcode",            # Gemini/Google tooling
    "Google.geminicodeassist"                # Gemini Code Assist
)

$VSCodePath = "C:\Program Files\Microsoft VS Code\bin\code.cmd"

# Try alternative paths
if (-not (Test-Path $VSCodePath)) {
    $VSCodePath = (Get-Command code.cmd -ErrorAction SilentlyContinue).Source
}

if (Test-Path $VSCodePath) {
    $InstalledExtensions = & $VSCodePath --list-extensions 2>$null
    foreach ($Extension in $VSCodeExtensions) {
        if ($InstalledExtensions -contains $Extension) {
            Write-Log "VS Code extension already installed: $Extension" "INFO"
            continue
        }

        Write-Log "Installing VS Code extension: $Extension" "INFO"
        try {
            & $VSCodePath --install-extension $Extension 2>&1 | ForEach-Object { Add-Content -Path $LogFile -Value $_ }
            if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 1) {
                Write-Log "Extension $Extension processed" "SUCCESS"
            }
        }
        catch {
            Write-Log "Error installing extension $Extension : $_" "ERROR"
        }
    }
}
else {
    Write-Log "VS Code command line not found. Extensions will need to be installed manually." "WARNING"
}

# ============================================================================
# REFRESH ENVIRONMENT VARIABLES
# ============================================================================
Write-Log "Refreshing environment variables..." "INFO"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# ============================================================================
# FINAL LOGGING
# ============================================================================
Write-Log "==========================================" "INFO"
Write-Log "Chocolatey installation script completed" "SUCCESS"
Write-Log "==========================================" "INFO"
Write-Log "Logs saved to: $LogFile" "INFO"

if ((Test-Path $ErrorLogFile) -and ((Get-Item -Path $ErrorLogFile).Length -gt 0)) {
    Write-Log "Errors logged to: $ErrorLogFile" "WARNING"
}

Write-Host "`nInstallation complete! Logs are available at:`n  $LogFolder" -ForegroundColor Green
Read-Host "Press Enter to exit"
