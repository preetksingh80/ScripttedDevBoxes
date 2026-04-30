# Winget Installation Script
# This script installs software via Windows Package Manager (Winget) with admin checks, software verification, and logging

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

$LogFile = Join-Path $LogFolder "Winget-Install-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$ErrorLogFile = Join-Path $LogFolder "Winget-Install-Errors-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

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
    
    Write-Log "Winget is not installed or not available" "WARNING"
    return $false
}

if (-not (Test-WingetInstalled)) {
    Write-Log "Winget not found. Installing Windows Package Manager..." "INFO"
    try {
        # Install from Microsoft Store or download
        $WingetUri = "https://aka.ms/getwinget"
        $WingetFile = "$env:TEMP\winget.msixbundle"
        
        Write-Log "Downloading Windows Package Manager..." "INFO"
        Invoke-WebRequest -Uri $WingetUri -OutFile $WingetFile -ErrorAction Stop
        
        Write-Log "Installing Windows Package Manager..." "INFO"
        Add-AppxPackage -Path $WingetFile -ErrorAction SilentlyContinue
        
        Remove-Item $WingetFile -Force -ErrorAction SilentlyContinue
        Write-Log "Windows Package Manager installed" "SUCCESS"
    }
    catch {
        Write-Log "Could not install Winget automatically: $_" "WARNING"
        Write-Log "Please install Winget manually from Microsoft Store or https://github.com/microsoft/winget-cli" "WARNING"
    }
}

# Refresh environment
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# ============================================================================
# FUNCTION TO CHECK IF SOFTWARE IS INSTALLED
# ============================================================================
function Test-SoftwareInstalled {
    param(
        [string]$PackageId,
        [string]$DisplayName
    )
    
    try {
        $InstalledPackages = winget list --id $PackageId -e --accept-source-agreements 2>$null
        if ($InstalledPackages -match [regex]::Escape($PackageId)) {
            Write-Log "$DisplayName is already installed" "INFO"
            return $true
        }
    }
    catch {}
    
    return $false
}

# ============================================================================
# INSTALLATION FUNCTION FOR WINGET
# ============================================================================
function Install-Software {
    param(
        [string]$PackageId,
        [string]$DisplayName,
        [string]$AdditionalArgs = ""
    )
    
    if (Test-SoftwareInstalled -PackageId $PackageId -DisplayName $DisplayName) {
        Write-Log "Skipping $DisplayName (already installed)" "INFO"
        return $true
    }
    
    Write-Host "Installing $DisplayName"
    Write-Log "Installing $DisplayName" "INFO"
    try {
        $PrimaryArgs = @(
            "install",
            "--id", $PackageId,
            "-e",
            "--accept-package-agreements",
            "--accept-source-agreements",
            "--scope", "machine",
            "--silent"
        )

        if ($AdditionalArgs) {
            $PrimaryArgs += $AdditionalArgs.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
        }

        & winget @PrimaryArgs 2>&1 | ForEach-Object { Add-Content -Path $LogFile -Value $_ }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Successfully installed $DisplayName" "SUCCESS"
            return $true
        }

        Write-Log "Primary install attempt failed for $DisplayName (Exit Code: $LASTEXITCODE). Retrying with compatibility flags..." "WARNING"
        $FallbackArgs = @(
            "install",
            "--id", $PackageId,
            "-e",
            "--accept-package-agreements",
            "--accept-source-agreements"
        )

        if ($AdditionalArgs) {
            $FallbackArgs += $AdditionalArgs.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
        }

        & winget @FallbackArgs 2>&1 | ForEach-Object { Add-Content -Path $LogFile -Value $_ }

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Successfully installed $DisplayName on retry" "SUCCESS"
            return $true
        }

        Write-Log "Failed to install $DisplayName (Exit Code: $LASTEXITCODE)" "ERROR"
        return $false
    }
    catch {
        Write-Log "Error installing $DisplayName : $_" "ERROR"
        return $false
    }
}

# ============================================================================
# INSTALL SOFTWARE
# ============================================================================
Write-Log "===========================================" "INFO"
Write-Log "Starting Winget software installation" "INFO"
Write-Log "===========================================" "INFO"

# Browsers and Drivers
Install-Software -PackageId "Google.Chrome" -DisplayName "Google Chrome browser"
Install-Software -PackageId "Google.ChromeDriver" -DisplayName "Google Chrome Driver"

# Development Tools
Install-Software -PackageId "Git.Git" -DisplayName "GIT"
Install-Software -PackageId "GitHub.GitHubDesktop" -DisplayName "GitHub Desktop"
Install-Software -PackageId "GitHub.cli" -DisplayName "GitHub CLI"
Install-Software -PackageId "OpenJS.NodeJS.LTS" -DisplayName "Node.js"
Install-Software -PackageId "Python.Python.3" -DisplayName "Python latest"
Install-Software -PackageId "Microsoft.DotNet.SDK.9" -DisplayName "Microsoft .NET SDK 9"
Install-Software -PackageId "Microsoft.DotNet.SDK.8" -DisplayName "Microsoft .NET SDK 8 (Core/LTS)"

# Docker
Install-Software -PackageId "Docker.DockerDesktop" -DisplayName "Docker Desktop"

# IDE and Editor
Install-Software -PackageId "Microsoft.VisualStudioCode" -DisplayName "Visual Studio Code"

# CLI Tools and Utilities
Install-Software -PackageId "7zip.7zip" -DisplayName "7Zip"
Install-Software -PackageId "Notepad++.Notepad++" -DisplayName "Notepad++"
Install-Software -PackageId "SQLite.SQLite" -DisplayName "SQLite"
Install-Software -PackageId "Microsoft.SQLServerManagementStudio" -DisplayName "SQL Server Management Studio"

# ============================================================================
# INSTALL TOOLS THAT MAY NEED NPM
# ============================================================================
Write-Log "Installing additional CLI tools via NPM..." "INFO"

try {
    # Wait for Node.js and npm to be available
    $NpmCmd = "npm.cmd"
    $MaxRetries = 5
    $Retry = 0
    
    while ((!(Get-Command $NpmCmd -ErrorAction SilentlyContinue)) -and ($Retry -lt $MaxRetries)) {
        Write-Log "Waiting for npm to be available... (Attempt $($Retry + 1)/$MaxRetries)" "WARNING"
        Start-Sleep -Seconds 3
        $Retry++
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    }
    
    if (-not (Get-Command npm.cmd -ErrorAction SilentlyContinue)) {
        throw "npm is not available after Node.js installation"
    }

    # Install TypeScript globally
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

    # Install GitHub Copilot CLI via GitHub CLI extension
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

    # Install Gemini CLI
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
catch {
    Write-Log "Error installing npm packages: $_" "ERROR"
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

if (Get-Command code.cmd -ErrorAction SilentlyContinue) {
    $InstalledExtensions = code.cmd --list-extensions 2>$null
    foreach ($Extension in $VSCodeExtensions) {
        if ($InstalledExtensions -contains $Extension) {
            Write-Log "VS Code extension already installed: $Extension" "INFO"
            continue
        }

        Write-Log "Installing VS Code extension: $Extension" "INFO"
        try {
            code.cmd --install-extension $Extension 2>&1 | ForEach-Object { Add-Content -Path $LogFile -Value $_ }
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
Write-Log "===========================================" "INFO"
Write-Log "Winget installation script completed" "SUCCESS"
Write-Log "===========================================" "INFO"
Write-Log "Logs saved to: $LogFile" "INFO"

if ((Test-Path $ErrorLogFile) -and ((Get-Item -Path $ErrorLogFile).Length -gt 0)) {
    Write-Log "Errors logged to: $ErrorLogFile" "WARNING"
}

Write-Host "`nInstallation complete! Logs are available at:`n  $LogFolder" -ForegroundColor Green
Read-Host "Press Enter to exit"
