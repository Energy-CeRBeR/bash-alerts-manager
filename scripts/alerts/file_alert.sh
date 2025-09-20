#!/bin/bash

# File Alert Handler
# ==================
# Handles file-based alert notifications with advanced formatting

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

COOLDOWN_FILE="/tmp/alert_manager_cooldown"

is_alert_in_cooldown() {
    local alert_type="$1"
    local cooldown_minutes="${ALERT_COOLDOWN:-5}"
    
    if [[ ! -f "$COOLDOWN_FILE" ]]; then
        return 1  
    fi
    
    local last_alert_time=$(grep "^$alert_type:" "$COOLDOWN_FILE" 2>/dev/null | cut -d: -f2)
    
    if [[ -z "$last_alert_time" ]]; then
        return 1 
    fi
    
    local current_time=$(date +%s)
    local time_diff=$(( (current_time - last_alert_time) / 60 ))
    
    if (( time_diff >= cooldown_minutes )); then
        return 1  
    fi
    
    return 0 
}

update_alert_cooldown() {
    local alert_type="$1"
    local current_time=$(date +%s)
    
    touch "$COOLDOWN_FILE"
    
    grep -v "^$alert_type:" "$COOLDOWN_FILE" > "${COOLDOWN_FILE}.tmp" 2>/dev/null || true
    
    echo "$alert_type:$current_time" >> "${COOLDOWN_FILE}.tmp"
    
    mv "${COOLDOWN_FILE}.tmp" "$COOLDOWN_FILE"
}

send_alert() {
    local alert_type="$1"
    local current_value="$2"
    local threshold="$3"
    local details="$4"
    
    if is_alert_in_cooldown "$alert_type"; then
        log_info "Alert $alert_type is in cooldown period, skipping..."
        return 0
    fi
    
    log_alert "$alert_type" "$current_value" "$threshold" "$details"
    
    update_alert_cooldown "$alert_type"  
}

generate_alert_summary() {
    local log_file="$1"
    
    if [[ ! -f "$log_file" ]]; then
        echo "No alerts found."
        return
    fi
    
    echo "Alert Summary Report"
    echo "==================="
    echo "Generated: $(date)"
    echo ""
    
    echo "Alert Counts:"
    echo "-------------"
    grep "Alert Type:" "$log_file" | awk -F': ' '{print $2}' | sort | uniq -c | sort -nr
    echo ""
    
    echo "Recent Alerts (Last 24 Hours):"
    echo "------------------------------"
    local yesterday=$(date -d "24 hours ago" '+%Y-%m-%d %H:%M:%S')
    awk -v since="$yesterday" '
        /^\[.*\] \[.*\]/ {
            timestamp = substr($0, 2, 19)
            if (timestamp >= since) print_section = 1
            else print_section = 0
        }
        print_section && /🚨 ALERT TRIGGERED 🚨/ {
            getline; print $0
            getline; getline; print "  " $0
            getline; print "  " $0
            getline; print "  " $0
            print ""
        }
    ' "$log_file"
}

main() {
    local action="${1:-help}"
    
    case "$action" in
        "send")
            if [[ $# -lt 4 ]]; then
                echo "Usage: $0 send <alert_type> <current_value> <threshold> [details]"
                exit 1
            fi
            send_alert "$2" "$3" "$4" "${5:-}"
            ;;
        "summary")
            local log_file="${2:-$LOG_FILE_PATH}"
            generate_alert_summary "$log_file"
            ;;
        "cooldown-status")
            if [[ -f "$COOLDOWN_FILE" ]]; then
                echo "Current Alert Cooldowns:"
                echo "======================="
                while IFS=: read -r alert_type timestamp; do
                    local current_time=$(date +%s)
                    local time_diff=$(( (current_time - timestamp) / 60 ))
                    local remaining=$(( ${ALERT_COOLDOWN:-5} - time_diff ))
                    if (( remaining > 0 )); then
                        echo "$alert_type: ${remaining} minutes remaining"
                    else
                        echo "$alert_type: cooldown expired"
                    fi
                done < "$COOLDOWN_FILE"
            else
                echo "No active cooldowns"
            fi
            ;;
        "help"|*)
            cat << EOF
File Alert Handler Usage:
========================

Commands:
  send <type> <value> <threshold> [details]  - Send an alert
  summary [log_file]                         - Generate alert summary
  cooldown-status                           - Show cooldown status
  help                                      - Show this help

Examples:
  $0 send "HIGH_CPU" "85.5%" "80%" "CPU details..."
  $0 summary /path/to/alerts.log
  $0 cooldown-status
EOF
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
