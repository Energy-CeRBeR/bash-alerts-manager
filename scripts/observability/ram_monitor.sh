#!/bin/bash

# RAM Monitor
# ===========
# Monitors memory usage and triggers alerts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
export PROJECT_DIR

CONFIG_FILE="$PROJECT_DIR/alert-manager.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

source "$SCRIPT_DIR/../utils/logger.sh"

THRESHOLD=${1:-85.0}

# Get memory usage percentage
get_memory_usage() {
    local mem_info=$(free | grep '^Mem:')
    local total=$(echo $mem_info | awk '{print $2}')
    local used=$(echo $mem_info | awk '{print $3}')
    local usage=$(echo "scale=2; $used * 100 / $total" | bc)
    echo "$usage"
}

# Get detailed memory information
get_memory_details() {
    local mem_info=$(free -h)
    local swap_info=$(free -h | grep '^Swap:')
    
    cat << EOF
Memory Details:
--------------
$mem_info

Top Memory Processes:
$(ps aux --sort=-%mem | head -6 | awk 'NR==1{print $0} NR>1{printf "  PID: %s MEM: %s%% CMD: %s %s\n", $2, $4, $11, $12}')

Memory Statistics:
$(cat /proc/meminfo | grep -E '^(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree):' | column -t)
EOF
}

# Main monitoring logic
main() {
    local current_mem=$(get_memory_usage)
    
    log_info "Memory Check - Current: ${current_mem}%, Threshold: ${THRESHOLD}%"
    
    # Compare with threshold
    if (( $(echo "$current_mem > $THRESHOLD" | bc -l) )); then
        local details=$(get_memory_details)
        log_alert "HIGH MEMORY USAGE" "${current_mem}%" "${THRESHOLD}%" "$details"
    fi
}

main "$@"
