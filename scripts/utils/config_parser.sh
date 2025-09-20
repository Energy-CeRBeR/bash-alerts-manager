#!/bin/bash

# Configuration Parser Utility
# ============================
# Provides functions to parse and validate configuration

validate_config() {
    local errors=0
    
    # Check required numeric values
    if ! [[ "$CPU_THRESHOLD" =~ ^[0-9]+\.?[0-9]*$ ]] || (( $(echo "$CPU_THRESHOLD > 100" | bc -l) )); then
        log_error "Invalid CPU_THRESHOLD: $CPU_THRESHOLD (must be 0-100)"
        ((errors++))
    fi
    
    if ! [[ "$RAM_THRESHOLD" =~ ^[0-9]+\.?[0-9]*$ ]] || (( $(echo "$RAM_THRESHOLD > 100" | bc -l) )); then
        log_error "Invalid RAM_THRESHOLD: $RAM_THRESHOLD (must be 0-100)"
        ((errors++))
    fi
    
    if ! [[ "$DISK_THRESHOLD" =~ ^[0-9]+\.?[0-9]*$ ]] || (( $(echo "$DISK_THRESHOLD > 100" | bc -l) )); then
        log_error "Invalid DISK_THRESHOLD: $DISK_THRESHOLD (must be 0-100)"
        ((errors++))
    fi
    
    if ! [[ "$PROCESS_THRESHOLD" =~ ^[0-9]+$ ]]; then
        log_error "Invalid PROCESS_THRESHOLD: $PROCESS_THRESHOLD (must be positive integer)"
        ((errors++))
    fi
    
    return $errors
}

get_system_info() {
    cat << EOF
System Information:
==================
Hostname: $(hostname)
OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")
Kernel: $(uname -r)
Uptime: $(uptime -p)
Load Average: $(uptime | awk -F'load average:' '{print $2}')
EOF
}
