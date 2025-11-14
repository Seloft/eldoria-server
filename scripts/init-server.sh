#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
TIMESTAMP=$(date +"[%H:%M:%S]")

log_info() {
    echo -e "${TIMESTAMP} ${GREEN}[INFO]:${NC} $1"
}

log_warn() {
    echo -e "${TIMESTAMP} ${YELLOW}[WARN]:${NC} $1"
}

log_error() {
    echo -e "${TIMESTAMP} ${RED}[ERROR]:${NC} $1"
}

# Create minecraft directory if it doesn't exist
mkdir -p /minecraft

# Initialize minecraft directory if empty
if [ ! -f "/minecraft/fabric-server-mc"*.jar ] && [ ! -f "/minecraft/server.jar" ]; then
    log_info "Initializing minecraft server files..."
    
    # Copy template files
    cp -r /minecraft-template/* /minecraft/ 2>/dev/null;
else
    log_info "Server files already exist, skipping template copy"
    echo
fi

# Change to minecraft directory
cd /minecraft

# Create essential directories
log_info "Creating essential directories..."
mkdir -p server-world logs backups mods

if [ $? -ne 0 ]; then
    log_error "Failed to create essential directories"
    exit 1
fi
log_info "Essential directories created successfully"
echo

# Set proper permissions
log_info "Setting directory permissions..."
chmod -R 755 server-world logs backups mods
chmod 755 /minecraft

# Ensure server.properties exists
if [ ! -f "server.properties" ]; then
    log_info "Creating default server.properties..."
    cat > server.properties << 'EOF'
          accepts-transfers=false
          allow-flight=false
          allow-nether=true
          broadcast-console-to-ops=true
          bug-report-link=
          difficulty=normal
          enable-command-block=false
          enable-jmx-monitoring=false
          enable-query=false
          enable-status=true
          enforce-secure-profile=true
          enforce-whitelist=false
          entity-broadcast-range-percentage=100
          force-gamemode=false
          function-permission-level=2
          gamemode=survival
          generate-structures=true
          generator-settings={}
          hardcore=false
          hide-online-players=false
          initial-disabled-packs=
          initial-enabled-packs=vanilla
          level-broadcast-range-percentage=100
          level-name=server-world
          level-seed=
          level-type=minecraft\:normal
          log-ips=true
          max-chained-neighbor-updates=1000000
          max-players=20
          max-tick-time=60000
          max-world-size=29999984
          motd=Minecraft Server
          network-compression-threshold=256
          online-mode=true
          op-permission-level=4
          player-idle-timeout=0
          prevent-proxy-connections=false
          pvp=true
          query.port=25565
          rate-limit=0
          enable-rcon=true
          rcon.port=25575
          rcon.password=
          broadcast-rcon-to-ops=true
          region-file-compression=deflate
          require-resource-pack=false
          resource-pack=
          resource-pack-id=
          resource-pack-prompt=
          resource-pack-sha1=
          server-ip=
          server-port=25565
          simulation-distance=10
          spawn-animals=true
          spawn-monsters=true
          spawn-npcs=true
          spawn-protection=7
          sync-chunk-writes=true
          text-filtering-config=
          use-native-transport=true
          view-distance=10
          white-list=false
          spawn-radius=1
EOF
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
echo

for dir in logs server-world backups; do
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