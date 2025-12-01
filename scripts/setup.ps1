# Eldoria Server - Setup Script for Windows
# Run this script in PowerShell

$ErrorActionPreference = "Continue"

# Configuration
$GITHUB_ORG = "Seloft"
$BASE_DIR = Split-Path -Parent $PSScriptRoot
$PARENT_DIR = Split-Path -Parent $BASE_DIR

# Repositories to clone
$REPOS = @(
    "eldoria-backup",
    "eldoria-backend",
    "eldoria-frontend"
)

function Write-ColorOutput {
    param (
        [string]$Type,
        [string]$Message
    )
    
    switch ($Type) {
        "INFO"  { Write-Host "[INFO] " -ForegroundColor Green -NoNewline; Write-Host $Message }
        "WARN"  { Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline; Write-Host $Message }
        "ERROR" { Write-Host "[ERROR] " -ForegroundColor Red -NoNewline; Write-Host $Message }
        "STEP"  { Write-Host "[STEP] " -ForegroundColor Cyan -NoNewline; Write-Host $Message }
    }
}

# Header
Write-Host ""
Write-Host "=======================================================" -ForegroundColor Blue
Write-Host "         Eldoria Server - Setup Script                 " -ForegroundColor Blue
Write-Host "=======================================================" -ForegroundColor Blue
Write-Host ""

Write-ColorOutput "INFO" "Base directory: $BASE_DIR"
Write-ColorOutput "INFO" "Parent directory: $PARENT_DIR"
Write-Host ""

# Check if git is installed
$gitVersion = & git --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "ERROR" "Git is not installed. Please install git first."
    exit 1
}

# Check if docker is installed
$dockerVersion = & docker --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "WARN" "Docker is not installed. You'll need it to run the server."
}

# Clone or update repositories
Write-ColorOutput "STEP" "Cloning/updating repositories..."
Write-Host ""

foreach ($repo in $REPOS) {
    $REPO_PATH = Join-Path $PARENT_DIR $repo
    
    if (Test-Path $REPO_PATH) {
        Write-ColorOutput "INFO" "Repository $repo already exists, pulling latest changes..."
        Push-Location $REPO_PATH
        $null = & git pull origin main 2>&1
        if ($LASTEXITCODE -ne 0) {
            $null = & git pull origin master 2>&1
        }
        Pop-Location
    }
    else {
        Write-ColorOutput "INFO" "Cloning $repo..."
        Push-Location $PARENT_DIR
        
        # Clone using HTTPS
        $output = & git clone "https://github.com/$GITHUB_ORG/$repo.git" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "INFO" "Cloned $repo successfully"
        }
        else {
            Write-ColorOutput "ERROR" "Failed to clone $repo. Please check your access permissions."
            Write-Host $output
            Pop-Location
            exit 1
        }
        
        Pop-Location
    }
}

Write-Host ""
Write-ColorOutput "STEP" "Verifying repository structure..."

# Verify all repos exist
$allReposOk = $true
foreach ($repo in $REPOS) {
    $REPO_PATH = Join-Path $PARENT_DIR $repo
    if (Test-Path $REPO_PATH) {
        Write-ColorOutput "INFO" "[OK] $repo found"
    }
    else {
        Write-ColorOutput "ERROR" "[X] $repo not found"
        $allReposOk = $false
    }
}

if (-not $allReposOk) {
    Write-ColorOutput "ERROR" "Some repositories are missing. Please clone them manually."
    exit 1
}

Write-Host ""
Write-ColorOutput "STEP" "Creating necessary directories..."

# Create local directories if needed
$dataDir = Join-Path $BASE_DIR "data"
if (-not (Test-Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
}

Write-Host ""
Write-ColorOutput "STEP" "Setting up environment..."

# Create .env file if it doesn't exist
$envFile = Join-Path $BASE_DIR ".env"
if (-not (Test-Path $envFile)) {
    Write-ColorOutput "INFO" "Creating .env file with default values..."
    $envContent = @"
# Minecraft Server Configuration
MEMORY=-Xmx6G -Xms3G
TZ=America/Sao_Paulo

# Minecraft Version
MC_VERSION=1.21.1
FABRIC_LOADER_VERSION=0.18.0
INSTALLER_VERSION=1.1.0

# RCON Configuration
MINECRAFT_RCON_PASSWORD=change_me_in_production

# Modrinth API (for mod management)
MODRINTH_AUTHORIZATION=your_modrinth_token_here

# Allowed Origins for Backend
ALLOWED_ORIGINS=http://minecraft-frontend,http://localhost

# Backup Configuration
KEEP_BACKUPS=5
BACKUP_INTERVAL=3600
"@
    $envContent | Out-File -FilePath $envFile -Encoding utf8
    Write-ColorOutput "WARN" "Please edit .env file with your actual configuration values!"
}
else {
    Write-ColorOutput "INFO" ".env file already exists"
}

Write-Host ""
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "                  Setup Complete!                      " -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host ""

Write-Host "Repository structure:"
Write-Host "  $PARENT_DIR\"
foreach ($repo in $REPOS) {
    Write-Host "    +-- $repo\"
}
Write-Host "    +-- eldoria-server\ (this repo)"
Write-Host ""

Write-Host "Next steps:"
Write-Host "  1. Edit .env file with your configuration"
Write-Host "  2. Run: docker compose -f minecraft-server.yaml build"
Write-Host "  3. Run: docker compose -f minecraft-server.yaml up -d"
Write-Host ""

Write-ColorOutput "INFO" "Happy gaming!"
