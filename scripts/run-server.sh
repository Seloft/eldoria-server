#!/bin/bash
set -euo pipefail

# Default values with environment variable support
: "${MEMORY:=-Xmx4G}"
: "${MINECRAFT_OPTS:=nogui}"

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

# Display startup information
echo
log_info "Minecraft version: ${MC_VERSION:-unknown}"
log_info "Fabric Loader version: ${FABRIC_LOADER_VERSION:-unknown}"
log_info "Memory allocation: $MEMORY"
log_info "Working directory: $(pwd)"
echo

# Find the Fabric server jar using the exact naming pattern
JAR="fabric-server-mc.${MC_VERSION}-loader.${FABRIC_LOADER_VERSION}-launcher.${INSTALLER_VERSION}.jar"

if [ ! -f "$JAR" ]; then
    log_error "Expected Fabric server jar not found: $JAR"
    echo
    log_info "Directory contents:"
    ls -la .
    echo
    log_info "Looking for any fabric-server-mc*.jar files:"
    find . -maxdepth 1 -name "fabric-server-mc*.jar" -type f || echo "  (none found)"
    echo
    log_error "Please ensure the Fabric server jar was downloaded correctly during build"
    exit 1
fi

log_info "Found Fabric server jar: $JAR"

# Validate Java installation
if ! command -v java >/dev/null 2>&1; then
    log_error "Java is not installed or not in PATH"
    exit 1
fi

# Show Java version
JAVA_VERSION=$(java -version 2>&1 | head -n 1)
log_info "Java: $JAVA_VERSION"

# Create necessary directories
mkdir -p logs server-world backups

STARTUP_COMMANDS_FILE="/minecraft/server-messages/startup-commands.txt"

if [ -f "$STARTUP_COMMANDS_FILE" ]; then
    log_info "Startup commands file found at: $STARTUP_COMMANDS_FILE"
    log_info "File contents:"
    cat "$STARTUP_COMMANDS_FILE" | grep -v '^#' | grep -v '^[[:space:]]*$' | head -5 | while read line; do
        echo "  → $line"
    done
    echo
    
    # Start server in background
    log_info "Starting server in background for RCON commands..."
    java $MEMORY -jar "$JAR" $MINECRAFT_OPTS &
    SERVER_PID=$!
    
    # Wait for server to start
    log_info "Waiting for server and RCON to be ready... (PID: $SERVER_PID)"
    timeout=120
    rcon_ready=false
    
    while [ $timeout -gt 0 ]; do
        if ! kill -0 $SERVER_PID 2>/dev/null; then
            log_error "Server process died during startup"
            exit 1
        fi
        
        # Check if RCON port is open
        if nc -z localhost 25575 2>/dev/null; then
            log_info "RCON port 25575 is open"
            rcon_ready=true
            break
        fi
        
        echo -n "."
        sleep 3
        timeout=$((timeout - 3))
    done
    echo
    
    if [ "$rcon_ready" = true ]; then
        log_info "Waiting additional 5 seconds for full server startup..."
        sleep 5
        
        # Test RCON connection first
        log_info "Testing RCON connection..."
        
        # Create test script
        cat > /tmp/test_rcon.py << 'EOF'
from mcrcon import MCRcon
import sys
try:
    with MCRcon('localhost', 'mgmm4103', port=25575) as mcr:
        resp = mcr.command('list')
        print('RCON test successful. Players online:', resp)
        sys.exit(0)
except Exception as e:
    print('RCON test failed:', str(e))
    sys.exit(1)
EOF
        
        if python3 /tmp/test_rcon.py; then
            log_info "RCON connection successful, executing startup commands..."
            
            # Execute commands using temporary files (MAIS SEGURO)
            command_count=0
            while IFS= read -r command; do
                # Remove caracteres especiais e espaços extras
                clean_command=$(echo "$command" | tr -d '\r\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
                
                if [[ ! "$clean_command" =~ ^# ]] && [[ -n "$clean_command" ]]; then
                    command_count=$((command_count + 1))
                    log_info "[$command_count] Executing: $clean_command"
                    
                    # Salvar comando limpo em arquivo temporário
                    echo "$clean_command" > /tmp/current_command.txt
                    
                    # Executar usando arquivo temporário
                    cat > /tmp/execute_command.py << 'EOF'
from mcrcon import MCRcon
import sys

try:
    with open('/tmp/current_command.txt', 'r') as f:
        command = f.read().strip()
    
    with MCRcon('localhost', 'mgmm4103', port=25575) as mcr:
        resp = mcr.command(command)
        if resp and resp.strip(): 
            print('Response:', resp)
        else:
            print('Command executed successfully')
        sys.exit(0)
except Exception as e:
    print('Error:', str(e))
    sys.exit(1)
EOF
                    
                    if python3 /tmp/execute_command.py; then
                        log_info "✓ Command completed successfully"
                    else
                        log_warn "✗ Failed to execute: $clean_command"
                    fi
                    
                    # Limpar arquivos temporários
                    rm -f /tmp/current_command.txt /tmp/execute_command.py
                    sleep 2
                fi
            done < "$STARTUP_COMMANDS_FILE"
            
            log_info "Completed executing $command_count startup commands"
        else
            log_warn "RCON connection failed, commands will not be executed"
            log_info "Make sure server.properties has:"
            log_info "  enable-rcon=true"
            log_info "  rcon.port=25575" 
            log_info "  rcon.password=minecraft123"
        fi
        
        # Limpar script de teste
        rm -f /tmp/test_rcon.py
    else
        log_warn "Timeout waiting for RCON to be ready"
    fi
    
    log_info "Continuing to monitor server process..."
    wait $SERVER_PID
    
else
    log_warn "No startup commands file found at: $STARTUP_COMMANDS_FILE"
    log_info "Current /minecraft/server-messages/ contents:"
    ls -la /minecraft/server-messages/ 2>/dev/null || log_warn "Directory /minecraft/server-messages/ does not exist"
    echo
    log_info "Starting server normally without startup commands"
    exec java $MEMORY -jar "$JAR" $MINECRAFT_OPTS
fi