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

# Start the Minecraft server
echo
log_info "Starting Minecraft server..."
exec java $MEMORY -jar "$JAR" $MINECRAFT_OPTS