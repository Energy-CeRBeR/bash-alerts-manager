#!/bin/bash

# System Information Utility
# ==========================
# Provides comprehensive system information gathering

get_system_overview() {
    cat << EOF
╔══════════════════════════════════════════════════════════════════════════════╗
║                            SYSTEM OVERVIEW                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝

🖥️  SYSTEM INFORMATION:
   Hostname: $(hostname)
   OS: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
   Kernel: $(uname -r)
   Architecture: $(uname -m)
   Uptime: $(uptime -p)

⚡ PERFORMANCE METRICS:
   Load Average: $(uptime | awk -F'load average:' '{print $2}')
   CPU Cores: $(nproc)
   Total Memory: $(free -h | awk '/^Mem:/ {print $2}')
   Available Memory: $(free -h | awk '/^Mem:/ {print $7}')

💾 STORAGE INFORMATION:
$(df -h | grep -E '^/dev/' | awk '{printf "   %s: %s used of %s (%s)\n", $1, $3, $2, $5}')

🔄 ACTIVE SERVICES:
   Total Processes: $(ps aux | wc -l)
   Active Users: $(who | wc -l)
   Network Connections: $(ss -tuln | wc -l)

EOF
}

get_resource_usage() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' || echo "N/A")
    local mem_usage=$(free | awk '/^Mem:/ {printf "%.1f", $3/$2 * 100.0}')
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    local process_count=$(ps aux | wc -l)
    
    cat << EOF
📊 CURRENT RESOURCE USAGE:
   CPU Usage: ${cpu_usage}%
   Memory Usage: ${mem_usage}%
   Disk Usage (/): ${disk_usage}%
   Process Count: $((process_count - 1))
EOF
}

get_network_info() {
    cat << EOF
🌐 NETWORK INFORMATION:
$(ip route | grep default | awk '{print "   Default Gateway: " $3}')
$(ip addr show | grep -E 'inet.*scope global' | awk '{print "   IP Address: " $2}' | head -3)
   DNS Servers: $(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | tr '\n' ' ')
EOF
}

# Export functions for use in other scripts
export -f get_system_overview
export -f get_resource_usage  
export -f get_network_info
