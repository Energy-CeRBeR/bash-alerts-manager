#!/bin/bash

# Disk Monitor
# ============
# Monitors disk usage and triggers alerts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

THRESHOLD=${1:-90.0}
DISK_PATH=${2:-"/"}

# Get disk usage percentage
get_disk_usage() {
    local usage=$(df "$DISK_PATH" | tail -1 | awk '{print $5}' | sed 's/%//')
    echo "$usage"
}

# Get detailed disk information
get_disk_details() {
    cat << EOF
Disk Details:
------------
Monitored Path: $DISK_PATH

Disk Usage Summary:
$(df -h "$DISK_PATH")

All Mounted Filesystems:
$(df -h | grep -v tmpfs | grep -v udev)

Largest Directories in $DISK_PATH:
$(du -h "$DISK_PATH" 2>/dev/null | sort -hr | head -10 || echo "Permission denied for some directories")

Disk I/O Statistics:
$(iostat -d 1 1 2>/dev/null | tail -n +4 || echo "iostat not available")
EOF
}

# Main monitoring logic
main() {
    # Check if path exists
    if [[ ! -d "$DISK_PATH" ]]; then
        log_error "Disk path does not exist: $DISK_PATH"
        return 1
    fi
    
    local current_disk=$(get_disk_usage)
    
    log_info "Disk Check - Path: $DISK_PATH, Current: ${current_disk}%, Threshold: ${THRESHOLD}%"
    
    # Compare with threshold
    if (( current_disk > THRESHOLD )); then
        local details=$(get_disk_details)
        log_alert "HIGH DISK USAGE" "${current_disk}%" "${THRESHOLD}%" "$details"
    fi
}

main "$@"
