#!/bin/bash

# CPU Monitor
# ===========
# Monitors CPU usage and triggers alerts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
export PROJECT_DIR

CONFIG_FILE="$PROJECT_DIR/alert-manager.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

source "$SCRIPT_DIR/../utils/logger.sh"

THRESHOLD=${1:-80.0}

# Get CPU usage (average over 1 second)
get_cpu_usage() {
    # Method 1: Using top command
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    
    # Method 2: Using /proc/stat (more reliable)
    if [[ -z "$cpu_usage" ]] || [[ "$cpu_usage" == "0.0" ]]; then
        # Read /proc/stat twice with 1 second interval
        local stat1=$(cat /proc/stat | head -1)
        sleep 1
        local stat2=$(cat /proc/stat | head -1)
        
        # Calculate CPU usage
        local idle1=$(echo $stat1 | awk '{print $5}')
        local total1=$(echo $stat1 | awk '{sum=0; for(i=2;i<=NF;i++) sum+=$i; print sum}')
        local idle2=$(echo $stat2 | awk '{print $5}')
        local total2=$(echo $stat2 | awk '{sum=0; for(i=2;i<=NF;i++) sum+=$i; print sum}')
        
        local idle_diff=$((idle2 - idle1))
        local total_diff=$((total2 - total1))
        
        if [[ $total_diff -gt 0 ]]; then
            cpu_usage=$(echo "scale=2; 100 * (1 - $idle_diff / $total_diff)" | bc)
        else
            cpu_usage="0.00"
        fi
    fi
    
    echo "$cpu_usage"
}

# Get detailed CPU information
get_cpu_details() {
    cat << EOF
CPU Details:
-----------
CPU Model: $(lscpu | grep "Model name" | cut -d: -f2 | xargs)
CPU Cores: $(nproc)
CPU Architecture: $(lscpu | grep "Architecture" | cut -d: -f2 | xargs)
CPU MHz: $(lscpu | grep "CPU MHz" | cut -d: -f2 | xargs)
Load Average (1m, 5m, 15m): $(uptime | awk -F'load average:' '{print $2}')

Top CPU Processes:
$(ps aux --sort=-%cpu | head -6 | awk 'NR==1{print $0} NR>1{printf "  %s %s %s %s %s\n", $2, $3, $4, $11, $12}')
EOF
}

# Main monitoring logic
main() {
    local current_cpu=$(get_cpu_usage)
    
    log_info "CPU Check - Current: ${current_cpu}%, Threshold: ${THRESHOLD}%"
    
    # Compare with threshold
    if (( $(echo "$current_cpu > $THRESHOLD" | bc -l) )); then
        local details=$(get_cpu_details)
        log_alert "HIGH CPU USAGE" "${current_cpu}%" "${THRESHOLD}%" "$details"
    fi
}

main "$@"
