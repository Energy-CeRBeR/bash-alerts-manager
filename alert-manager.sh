#!/bin/bash

# Alert Manager - Main Entry Point
# ================================
# Author: Alert Manager System
# Description: Main script to run the alert manager system

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "$SCRIPT_DIR/alert-manager.conf" ]]; then
    echo "ERROR: alert-manager.conf not found in current directory"
    echo "Please run this script from the alert-manager root directory"
    exit 1
fi

source "$SCRIPT_DIR/alert-manager.conf"

check_dependencies() {
    local missing_deps=()
    
    for cmd in bc ps free df top uptime; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "ERROR: Missing required dependencies: ${missing_deps[*]}"
        echo "Please install missing packages and try again"
        exit 1
    fi
}

show_banner() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                              ALERT MANAGER                                   ║
║                         System Monitoring Tool                               ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
}

show_usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
  run                    - Run monitoring checks once
  install               - Install and setup cron job
  uninstall            - Remove cron job
  status               - Show current status and configuration
  test                 - Run test with low thresholds
  summary              - Show alert summary from log file
  help                 - Show this help message

Options:
  --config FILE        - Use custom configuration file
  --verbose           - Enable verbose output
  --dry-run           - Show what would be done without executing

Examples:
  $0 run                          # Run monitoring once
  $0 install                      # Setup cron job
  $0 test                         # Test with low thresholds
  $0 status                       # Show current status
  $0 summary                      # Show alert summary
EOF
}

show_status() {
    echo "Alert Manager Status"
    echo "==================="
    echo ""
    
    echo "Configuration:"
    echo "  Config File: $SCRIPT_DIR/alert-manager.conf"
    echo "  Log File: ${LOG_FILE}"
    echo "  Check Interval: ${CHECK_INTERVAL} minutes"
    echo "  Test Mode: ${TEST_MODE:-false}"
    echo ""
    
    echo "Monitoring Thresholds:"
    if [[ "${TEST_MODE:-false}" == "true" ]]; then
        echo "  CPU: ${TEST_CPU_THRESHOLD:-$CPU_THRESHOLD}% (TEST MODE)"
        echo "  Memory: ${TEST_RAM_THRESHOLD:-$RAM_THRESHOLD}% (TEST MODE)"
        echo "  Disk: ${TEST_DISK_THRESHOLD:-$DISK_THRESHOLD}% (TEST MODE)"
        echo "  Processes: ${TEST_PROCESS_THRESHOLD:-$PROCESS_THRESHOLD} (TEST MODE)"
    else
        echo "  CPU: ${CPU_THRESHOLD}%"
        echo "  Memory: ${RAM_THRESHOLD}%"
        echo "  Disk: ${DISK_THRESHOLD}%"
        echo "  Processes: ${PROCESS_THRESHOLD}"
    fi
    echo ""
    
    echo "Cron Job Status:"
    if crontab -l 2>/dev/null | grep -q "alert-manager.sh"; then
        echo "  Status: INSTALLED"
        echo "  Schedule: $(crontab -l 2>/dev/null | grep "alert-manager.sh" | awk '{print $1, $2, $3, $4, $5}')"
    else
        echo "  Status: NOT INSTALLED"
    fi
    echo ""
    
    echo "Log File Status:"
    if [[ -f "${LOG_FILE}" ]]; then
        echo "  File: EXISTS"
        echo "  Size: $(du -h "${LOG_FILE}" | cut -f1)"
        echo "  Last Modified: $(stat -c %y "${LOG_FILE}" 2>/dev/null | cut -d. -f1)"
        echo "  Alert Count: $(grep -c "🚨 ALERT TRIGGERED 🚨" "${LOG_FILE}" 2>/dev/null || echo "0")"
    else
        echo "  File: NOT EXISTS"
    fi
}

install_cron() {
    local cron_schedule="*/${CHECK_INTERVAL} * * * *"
    local cron_command="$SCRIPT_DIR/alert-manager.sh run >> $SCRIPT_DIR/cron.log 2>&1"
    
    echo "Installing Alert Manager cron job..."
    echo "Schedule: Every ${CHECK_INTERVAL} minutes"
    echo "Command: $cron_command"
    
    crontab -l > /tmp/crontab_backup 2>/dev/null || true
    
    crontab -l 2>/dev/null | grep -v "alert-manager.sh" > /tmp/crontab_new || true
    
    echo "$cron_schedule $cron_command" >> /tmp/crontab_new
    
    crontab /tmp/crontab_new
    
    echo "✅ Cron job installed successfully!"
    echo "The alert manager will run every ${CHECK_INTERVAL} minutes."
    echo "Logs will be written to: $SCRIPT_DIR/cron.log"
}

uninstall_cron() {
    echo "Removing Alert Manager cron job..."
    
    crontab -l 2>/dev/null | grep -v "alert-manager.sh" > /tmp/crontab_new || true
    crontab /tmp/crontab_new
    
    echo "✅ Cron job removed successfully!"
}

run_monitoring() {
    echo "Starting Alert Manager monitoring..."
    
    chmod +x "$SCRIPT_DIR/scripts/alert-manager.sh"
    chmod +x "$SCRIPT_DIR/scripts/observability/"*.sh
    chmod +x "$SCRIPT_DIR/scripts/alerts/"*.sh
    
    "$SCRIPT_DIR/scripts/alert-manager.sh"
    
    echo "Monitoring completed."
}

run_test() {
    echo "Running Alert Manager in TEST MODE..."
    echo "Using low thresholds to trigger alerts for testing..."
    
    local original_test_mode="${TEST_MODE:-false}"
    export TEST_MODE=true
    
    run_monitoring
    
    export TEST_MODE="$original_test_mode"
    
    echo ""
    echo "Test completed! Check the log file for alerts:"
    echo "  Log file: ${LOG_FILE}"
    echo "  View alerts: tail -50 '${LOG_FILE}'"
}

show_summary() {
    if [[ -f "$SCRIPT_DIR/scripts/alerts/file_alert.sh" ]]; then
        "$SCRIPT_DIR/scripts/alerts/file_alert.sh" summary "${LOG_FILE}"
    else
        echo "Alert summary script not found"
        exit 1
    fi
}

main() {
    local command="${1:-help}"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --verbose)
                set -x
                shift
                ;;
            --dry-run)
                echo "DRY RUN MODE - No changes will be made"
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    command="${1:-help}"
    
    case "$command" in
        "run")
            check_dependencies
            run_monitoring
            ;;
        "install")
            check_dependencies
            install_cron
            ;;
        "uninstall")
            uninstall_cron
            ;;
        "status")
            show_status
            ;;
        "test")
            check_dependencies
            run_test
            ;;
        "summary")
            show_summary
            ;;
        "help"|*)
            show_banner
            echo ""
            show_usage
            ;;
    esac
}

main "$@"
