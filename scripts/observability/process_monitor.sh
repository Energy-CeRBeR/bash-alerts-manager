#!/bin/bash

# Process Monitor
# ===============
# Monitors process count and triggers alerts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

THRESHOLD=${1:-200}

# Get current process count
get_process_count() {
    local count=$(ps aux | wc -l)
    # Subtract 1 for header line
    echo $((count - 1))
}

# Get detailed process information
get_process_details() {
    cat << EOF
Process Details:
---------------
Total Processes: $(get_process_count)
Running Processes: $(ps aux | awk '$8 ~ /^R/ {count++} END {print count+0}')
Sleeping Processes: $(ps aux | awk '$8 ~ /^S/ {count++} END {print count+0}')
Zombie Processes: $(ps aux | awk '$8 ~ /^Z/ {count++} END {print count+0}')

Process Summary by State:
$(ps aux | awk 'NR>1 {state[$8]++} END {for (s in state) printf "  %s: %d\n", s, state[s]}' | sort)

Top Processes by CPU:
$(ps aux --sort=-%cpu | head -6)

Top Processes by Memory:
$(ps aux --sort=-%mem | head -6)

Process Tree (top level):
$(pstree -p | head -10)
EOF
}

# Main monitoring logic
main() {
    local current_processes=$(get_process_count)
    
    log_info "Process Check - Current: $current_processes, Threshold: $THRESHOLD"
    
    # Compare with threshold
    if (( current_processes > THRESHOLD )); then
        local details=$(get_process_details)
        log_alert "HIGH PROCESS COUNT" "$current_processes" "$THRESHOLD" "$details"
    fi
}

main "$@"
