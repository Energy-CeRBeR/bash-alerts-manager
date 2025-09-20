#!/bin/bash

# Logger Utility
# ==============
# Provides logging functions with timestamps and formatting

LOG_FILE_PATH=""

init_logger() {
    local log_file="$1"
    
    # Handle empty or undefined log file
    if [[ -z "$log_file" ]]; then
        log_file="alerts.log"
        echo "WARNING: LOG_FILE not specified, using default: $log_file"
    fi
    
    # Create absolute path for log file
    if [[ "$log_file" = /* ]]; then
        LOG_FILE_PATH="$log_file"
    else
        # Use PROJECT_DIR instead of SCRIPT_DIR parent
        if [[ -n "${PROJECT_DIR:-}" ]]; then
            LOG_FILE_PATH="$PROJECT_DIR/$log_file"
        else
            LOG_FILE_PATH="$(dirname "$(dirname "$SCRIPT_DIR")")/$log_file"
        fi
    fi
    
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE_PATH")"
    
    # Create log file if it doesn't exist
    touch "$LOG_FILE_PATH"
    
    # Verify log file is writable
    if [[ ! -w "$LOG_FILE_PATH" ]]; then
        echo "ERROR: Cannot write to log file: $LOG_FILE_PATH"
        exit 1
    fi
    
    echo "Log file initialized: $LOG_FILE_PATH"
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local formatted_message="[$timestamp] [$level] $message"
    
    if [[ -z "$LOG_FILE_PATH" ]]; then
        echo "ERROR: Logger not initialized. Call init_logger first."
        echo "$formatted_message"
        return 1
    fi
    
    echo "$formatted_message" | tee -a "$LOG_FILE_PATH"
}

log_info() {
    log_message "INFO" "$1"
}

log_warn() {
    log_message "WARN" "$1"
}

log_error() {
    log_message "ERROR" "$1"
}

log_alert() {
    local alert_type="$1"
    local current_value="$2"
    local threshold="$3"
    local additional_info="$4"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat >> "$LOG_FILE_PATH" << EOF

🚨 ALERT TRIGGERED 🚨
=====================
Timestamp: $timestamp
Alert Type: $alert_type
Current Value: $current_value
Threshold: $threshold
Status: CRITICAL
$additional_info
=====================

EOF
    
    echo "🚨 ALERT: $alert_type - Current: $current_value, Threshold: $threshold"
}
