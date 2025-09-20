#!/bin/bash

# Alert Formatter Utility
# =======================
# Provides beautiful formatting for alerts and reports

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Unicode symbols
ALERT_SYMBOL="🚨"
INFO_SYMBOL="ℹ️"
SUCCESS_SYMBOL="✅"
WARNING_SYMBOL="⚠️"
ERROR_SYMBOL="❌"
CHART_SYMBOL="📊"

format_alert_header() {
    local alert_type="$1"
    local timestamp="$2"
    
    cat << EOF
╔══════════════════════════════════════════════════════════════════════════════╗
║ ${ALERT_SYMBOL} CRITICAL ALERT: ${alert_type}$(printf "%*s" $((50 - ${#alert_type})) "")║
╠══════════════════════════════════════════════════════════════════════════════╣
║ Timestamp: ${timestamp}$(printf "%*s" $((61 - ${#timestamp})) "")║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
}

format_metric_comparison() {
    local metric_name="$1"
    local current_value="$2"
    local threshold="$3"
    local unit="$4"
    
    cat << EOF
📈 METRIC COMPARISON:
   ${metric_name}: ${current_value}${unit} (Threshold: ${threshold}${unit})
   Status: $(if (( $(echo "$current_value > $threshold" | bc -l 2>/dev/null || echo "0") )); then echo "🔴 EXCEEDED"; else echo "🟢 NORMAL"; fi)
EOF
}

format_progress_bar() {
    local current="$1"
    local max="$2"
    local width="${3:-50}"
    
    local percentage=$(echo "scale=0; $current * 100 / $max" | bc)
    local filled=$(echo "scale=0; $current * $width / $max" | bc)
    local empty=$((width - filled))
    
    printf "["
    printf "%*s" "$filled" | tr ' ' '█'
    printf "%*s" "$empty" | tr ' ' '░'
    printf "] %d%%\n" "$percentage"
}

format_table_header() {
    local title="$1"
    echo "┌─────────────────────────────────────────────────────────────────────────────┐"
    printf "│ %-75s │\n" "$title"
    echo "├─────────────────────────────────────────────────────────────────────────────┤"
}

format_table_footer() {
    echo "└─────────────────────────────────────────────────────────────────────────────┘"
}

format_table_row() {
    local col1="$1"
    local col2="$2"
    printf "│ %-35s │ %-37s │\n" "$col1" "$col2"
}

# Export functions
export -f format_alert_header
export -f format_metric_comparison
export -f format_progress_bar
export -f format_table_header
export -f format_table_footer
export -f format_table_row
