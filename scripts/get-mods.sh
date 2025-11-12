#!/bin/bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "[$(date '+%H:%M:%S')] ${GREEN}[INFO]:${NC} $1"
}

log_warn() {
    echo -e "[$(date '+%H:%M:%S')] ${YELLOW}[WARN]:${NC} $1"
}

log_error() {
    echo -e "[$(date '+%H:%M:%S')] ${RED}[ERROR]:${NC} $1"
}

# Configuration
MODS_DIR="/minecraft/mods"
MODS_LIST_FILE="/minecraft/mods-list.json"

echo
log_info "=== DOWNLOADING MODS ==="
echo

# Install jq if not available
if ! command -v jq >/dev/null 2>&1; then
    log_info "Installing jq..."
    apt-get update && apt-get install -y jq
fi

# Create mods directory
mkdir -p "$MODS_DIR"

# Check if mods list exists
if [ ! -f "$MODS_LIST_FILE" ]; then
    log_error "Mods list not found: $MODS_LIST_FILE"
    exit 1
fi

# Count mods
TOTAL_MODS=$(jq length "$MODS_LIST_FILE")
log_info "Found $TOTAL_MODS mods to download"
echo

DOWNLOADED=0
FAILED=0

# Download each mod
for i in $(seq 0 $((TOTAL_MODS - 1))); do
    MOD_NAME=$(jq -r ".[$i].modname" "$MODS_LIST_FILE")
    MOD_URL=$(jq -r ".[$i][\"url-download\"]" "$MODS_LIST_FILE")
    
    # Simple filename: just use the filename from URL
    FILENAME=$(basename "$MOD_URL")
    
    log_info "[$((i + 1))/$TOTAL_MODS] Downloading: $MOD_NAME"
    log_info "URL: $MOD_URL"
    
    if wget -q --show-progress -O "$MODS_DIR/$FILENAME" "$MOD_URL"; then
        log_info "✓ Downloaded: $FILENAME"
        DOWNLOADED=$((DOWNLOADED + 1))
    else
        log_error "✗ Failed: $MOD_NAME"
        FAILED=$((FAILED + 1))
    fi
    
    echo
done

# Summary
echo
log_info "=== SUMMARY ==="
log_info "Downloaded: $DOWNLOADED/$TOTAL_MODS mods"

if [ $FAILED -gt 0 ]; then
    log_warn "Failed: $FAILED mods"
fi

log_info "Mods directory:"
ls -la "$MODS_DIR/"
echo