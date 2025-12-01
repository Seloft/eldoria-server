#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Configuration
GITHUB_ORG="Seloft"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARENT_DIR="$(dirname "$BASE_DIR")"

# Repositories to clone
REPOS=(
    "minecraft-backup"
    "minecraft-backend"
    "minecraft-frontend"
)

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           Eldoria Server - Setup Script                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

log_info "Base directory: $BASE_DIR"
log_info "Parent directory: $PARENT_DIR"
echo

# Check if git is installed
if ! command -v git &> /dev/null; then
    log_error "Git is not installed. Please install git first."
    exit 1
fi

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    log_warn "Docker is not installed. You'll need it to run the server."
fi

# Clone or update repositories
log_step "Cloning/updating repositories..."
echo

for repo in "${REPOS[@]}"; do
    REPO_PATH="$PARENT_DIR/$repo"
    
    if [ -d "$REPO_PATH" ]; then
        log_info "Repository $repo already exists, pulling latest changes..."
        cd "$REPO_PATH"
        git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || log_warn "Could not pull updates for $repo"
        cd "$BASE_DIR"
    else
        log_info "Cloning $repo..."
        cd "$PARENT_DIR"
        
        # Try SSH first, then HTTPS
        if git clone "git@github.com:$GITHUB_ORG/$repo.git" 2>/dev/null; then
            log_info "Cloned $repo via SSH"
        elif git clone "https://github.com/$GITHUB_ORG/$repo.git" 2>/dev/null; then
            log_info "Cloned $repo via HTTPS"
        else
            log_error "Failed to clone $repo. Please check your access permissions."
            exit 1
        fi
        cd "$BASE_DIR"
    fi
done

echo
log_step "Verifying repository structure..."

# Verify all repos exist
ALL_REPOS_OK=true
for repo in "${REPOS[@]}"; do
    REPO_PATH="$PARENT_DIR/$repo"
    if [ -d "$REPO_PATH" ]; then
        log_info "✓ $repo found"
    else
        log_error "✗ $repo not found"
        ALL_REPOS_OK=false
    fi
done

if [ "$ALL_REPOS_OK" = false ]; then
    log_error "Some repositories are missing. Please clone them manually."
    exit 1
fi

echo
log_step "Creating necessary directories..."

# Create local directories if needed
mkdir -p "$BASE_DIR/data"

echo
log_step "Setting up environment..."

# Create .env file if it doesn't exist
ENV_FILE="$BASE_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    log_info "Creating .env file with default values..."
    cat > "$ENV_FILE" << 'EOF'
# Minecraft Server Configuration
MEMORY=-Xmx6G -Xms3G
TZ=America/Sao_Paulo

# RCON Configuration
MINECRAFT_RCON_PASSWORD=change_me_in_production

# Modrinth API (for mod management)
MODRINTH_AUTHORIZATION=your_modrinth_token_here

# Allowed Origins for Backend
ALLOWED_ORIGINS=http://minecraft-frontend,http://localhost

# Backup Configuration
KEEP_BACKUPS=5
BACKUP_INTERVAL=3600
EOF
    log_warn "Please edit .env file with your actual configuration values!"
else
    log_info ".env file already exists"
fi

echo
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                    Setup Complete!                        ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo "Repository structure:"
echo "  $PARENT_DIR/"
for repo in "${REPOS[@]}"; do
    echo "    ├── $repo/"
done
echo "    └── eldoria-server/ (this repo)"
echo

echo "Next steps:"
echo "  1. Edit .env file with your configuration"
echo "  2. Run: docker compose -f minecraft-server.yaml build"
echo "  3. Run: docker compose -f minecraft-server.yaml up -d"
echo

log_info "Happy gaming! 🎮"
