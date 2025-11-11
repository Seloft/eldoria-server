#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create minecraft directory if it doesn't exist
mkdir -p /minecraft

# Initialize minecraft directory if empty
if [ ! -f "/minecraft/fabric-server-mc"*.jar ] && [ ! -f "/minecraft/server.jar" ]; then
    log_info "Initializing minecraft server files..."
    
    # Copy template files
    if cp -r /minecraft-template/* /minecraft/ 2>/dev/null; then
        log_info "Server files copied successfully"
    else
        log_warn "Some files couldn't be copied, trying individual copy..."
        for item in /minecraft-template/*; do
            basename_item=$(basename "$item")
            if cp -r "$item" "/minecraft/" 2>/dev/null; then
                log_info "Copied $basename_item"
            else
                log_warn "Failed to copy $basename_item"
            fi
        done
    fi
else
    log_info "Server files already exist, skipping template copy"
fi

# Change to minecraft directory
cd /minecraft

# Create essential directories
log_info "Creating essential directories..."
mkdir -p world logs backups mods server-config

# Set proper permissions
log_info "Setting directory permissions..."
chmod -R 755 world logs backups mods server-config
chmod 755 /minecraft

# Ensure server.properties exists
if [ ! -f "server.properties" ]; then
    if [ -f "server-config/server.properties" ]; then
        log_info "Copying server.properties from server-config..."
        cp server-config/server.properties server.properties
    else
        log_info "Creating default server.properties..."
        cat > server.properties << 'EOF'
#Minecraft server properties
server-port=25565
max-players=20
online-mode=true
white-list=false
level-name=world
gamemode=survival
difficulty=normal
pvp=true
enable-command-block=false
motd=A Minecraft Server
EOF
    fi
    chmod 644 server.properties
    log_info "server.properties configured"
else
    log_info "server.properties already exists"
fi

# Ensure EULA is accepted
if [ ! -f "eula.txt" ]; then
    echo "eula=true" > eula.txt
    log_info "EULA accepted"
fi
chmod 644 eula.txt

# Test directory permissions
log_info "Testing directory permissions..."
for dir in logs world backups; do
    if touch "$dir/test.tmp" 2>/dev/null; then
        rm -f "$dir/test.tmp"
        log_info "$dir directory is writable"
    else
        log_error "Cannot write to $dir directory"
        exit 1
    fi
done

# Handle graceful shutdown
cleanup() {
    log_info "Received shutdown signal, stopping server gracefully..."
    if [ -n "${SERVER_PID:-}" ]; then
        kill -TERM "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
    exit 0
}

trap cleanup SIGTERM SIGINT

# Start server
log_info "Starting server as user: $(whoami)"
exec ./run-server.sh