#!/bin/bash

# Alert Manager - Main Script
# ===========================
# Author: Alert Manager System
# Description: Monitors system resources and generates alerts

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration
CONFIG_FILE="$PROJECT_DIR/alert-manager.conf"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

# Source utility functions
source "$SCRIPT_DIR/utils/logger.sh"
source "$SCRIPT_DIR/utils/config_parser.sh"

# Initialize logging with validation
if [[ -z "${LOG_FILE:-}" ]]; then
    echo "WARNING: LOG_FILE not set in config, using default"
    LOG_FILE="alerts.log"
fi

init_logger "$LOG_FILE"

log_info "Alert Manager started - $(date)"

# Apply test mode if enabled
if [[ "${TEST_MODE:-false}" == "true" ]]; then
    log_info "TEST MODE ENABLED - Using low thresholds for testing"
    CPU_THRESHOLD=${TEST_CPU_THRESHOLD:-$CPU_THRESHOLD}
    RAM_THRESHOLD=${TEST_RAM_THRESHOLD:-$RAM_THRESHOLD}
    DISK_THRESHOLD=${TEST_DISK_THRESHOLD:-$DISK_THRESHOLD}
    PROCESS_THRESHOLD=${TEST_PROCESS_THRESHOLD:-$PROCESS_THRESHOLD}
    TEMPERATURE_THRESHOLD=${TEST_TEMPERATURE_THRESHOLD:-$TEMPERATURE_THRESHOLD}
    NETWORK_CONNECTIONS_THRESHOLD=${TEST_NETWORK_CONNECTIONS_THRESHOLD:-$NETWORK_CONNECTIONS_THRESHOLD}
    NETWORK_TRAFFIC_THRESHOLD=${TEST_NETWORK_TRAFFIC_THRESHOLD:-$NETWORK_TRAFFIC_THRESHOLD}
fi

# Check if alerts are enabled
if [[ "${ENABLE_ALERTS:-true}" != "true" ]]; then
    log_info "Alerts are disabled in configuration"
    exit 0
fi

# Run monitoring checks
check_cpu() {
    if [[ "${CPU_ALERT_ENABLED:-true}" == "true" ]]; then
        "$SCRIPT_DIR/observability/cpu_monitor.sh" "$CPU_THRESHOLD"
    fi
}

check_memory() {
    if [[ "${RAM_ALERT_ENABLED:-true}" == "true" ]]; then
        "$SCRIPT_DIR/observability/ram_monitor.sh" "$RAM_THRESHOLD"
    fi
}

check_disk() {
    if [[ "${DISK_ALERT_ENABLED:-true}" == "true" ]]; then
        "$SCRIPT_DIR/observability/disk_monitor.sh" "$DISK_THRESHOLD" "${DISK_PATH:-/}"
    fi
}

check_processes() {
    if [[ "${PROCESS_ALERT_ENABLED:-true}" == "true" ]]; then
        "$SCRIPT_DIR/observability/process_monitor.sh" "$PROCESS_THRESHOLD"
    fi
}

check_temperature() {
    if [[ "${TEMPERATURE_ALERT_ENABLED:-true}" == "true" ]]; then
        "$SCRIPT_DIR/observability/temperature_monitor.sh" "$TEMPERATURE_THRESHOLD"
    fi
}

check_network() {
    if [[ "${NETWORK_ALERT_ENABLED:-true}" == "true" ]]; then
        "$SCRIPT_DIR/observability/network_monitor.sh" "$NETWORK_CONNECTIONS_THRESHOLD" "$NETWORK_TRAFFIC_THRESHOLD"
    fi
}

# Execute all checks
log_info "Starting system monitoring checks..."

check_cpu
check_memory  
check_disk
check_processes
check_temperature
check_network

log_info "Monitoring checks completed - $(date)"
