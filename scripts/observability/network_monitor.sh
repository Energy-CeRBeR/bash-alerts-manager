#!/bin/bash

# Network Monitor
# ===============
# Мониторит сетевую активность и генерирует алерты

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
export PROJECT_DIR

CONFIG_FILE="$PROJECT_DIR/alert-manager.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

source "$SCRIPT_DIR/../utils/logger.sh"

CONNECTIONS_THRESHOLD=${1:-1000}
TRAFFIC_THRESHOLD_MB=${2:-1000}

# Получить количество активных соединений
get_active_connections() {
    # Использовать ss (современная замена netstat)
    if command -v ss &> /dev/null; then
        ss -tan | grep -c ESTAB || echo "0"
    else
        netstat -tan 2>/dev/null | grep -c ESTABLISHED || echo "0"
    fi
}

# Получить статистику сетевого трафика
get_network_traffic() {
    local interface=${1:-eth0}
    
    # Попробовать найти активный интерфейс
    if ! ip link show "$interface" &> /dev/null; then
        # Найти первый активный интерфейс (не lo)
        interface=$(ip -o link show | awk -F': ' '{print $2}' | grep -v "lo" | head -1)
    fi
    
    if [[ -f /proc/net/dev ]]; then
        local stats=$(grep "$interface" /proc/net/dev | awk '{print $2,$10}')
        local rx_bytes=$(echo $stats | awk '{print $1}')
        local tx_bytes=$(echo $stats | awk '{print $2}')
        
        # Конвертировать в MB
        local rx_mb=$(echo "scale=2; $rx_bytes / 1024 / 1024" | bc)
        local tx_mb=$(echo "scale=2; $tx_bytes / 1024 / 1024" | bc)
        
        echo "$interface $rx_mb $tx_mb"
    else
        echo "N/A 0 0"
    fi
}

# Получить детальную информацию о соединениях
get_connection_details() {
    cat << EOF
Детали сетевых соединений:
-------------------------
Всего активных соединений: $(get_active_connections)

Соединения по состояниям:
EOF
    
    if command -v ss &> /dev/null; then
        ss -tan | awk 'NR>1 {print $1}' | sort | uniq -c | sed 's/^/  /'
    else
        netstat -tan 2>/dev/null | awk 'NR>2 {print $6}' | sort | uniq -c | sed 's/^/  /'
    fi
    
    cat << EOF

Топ 10 соединений по IP:
EOF
    
    if command -v ss &> /dev/null; then
        ss -tan | awk 'NR>1 {print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10 | sed 's/^/  /'
    else
        netstat -tan 2>/dev/null | awk 'NR>2 {print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10 | sed 's/^/  /'
    fi
}

# Получить статистику сетевых интерфейсов
get_network_interfaces() {
    cat << EOF

Сетевые интерфейсы:
------------------
EOF
    
    ip -s link show | grep -E "^[0-9]+:|RX:|TX:" | sed 's/^/  /'
    
    cat << EOF

Статистика трафика:
------------------
EOF
    
    for iface in $(ip -o link show | awk -F': ' '{print $2}' | grep -v "lo"); do
        local traffic=$(get_network_traffic "$iface")
        local iface_name=$(echo $traffic | awk '{print $1}')
        local rx=$(echo $traffic | awk '{print $2}')
        local tx=$(echo $traffic | awk '{print $3}')
        echo "  ${iface_name}: RX=${rx}MB, TX=${tx}MB"
    done
}

# Проверить доступность хостов
check_connectivity() {
    local hosts=("8.8.8.8" "1.1.1.1")
    
    cat << EOF

Проверка связи:
--------------
EOF
    
    for host in "${hosts[@]}"; do
        if ping -c 1 -W 2 "$host" &> /dev/null; then
            echo "  ${host}: ✓ Доступен"
        else
            echo "  ${host}: ✗ Недоступен"
        fi
    done
}

# Основная логика мониторинга
main() {
    local connections=$(get_active_connections)
    
    log_info "Network Check - Active Connections: ${connections}, Threshold: ${CONNECTIONS_THRESHOLD}"
    
    # Проверка количества соединений
    if (( connections > CONNECTIONS_THRESHOLD )); then
        local details=$(get_connection_details)
        details="${details}\n$(get_network_interfaces)"
        details="${details}\n$(check_connectivity)"
        log_alert "HIGH NETWORK CONNECTIONS" "${connections}" "${CONNECTIONS_THRESHOLD}" "$details"
    fi
    
    # Проверка сетевых интерфейсов
    local default_iface=$(ip route | grep default | awk '{print $5}' | head -1)
    if [[ -n "$default_iface" ]]; then
        local traffic=$(get_network_traffic "$default_iface")
        local rx_mb=$(echo $traffic | awk '{print $2}')
        local tx_mb=$(echo $traffic | awk '{print $3}')
        local total_mb=$(echo "$rx_mb + $tx_mb" | bc)
        
        log_info "Network Traffic - Interface: ${default_iface}, RX: ${rx_mb}MB, TX: ${tx_mb}MB"
        
        # Проверка трафика (если превышен порог)
        if (( $(echo "$total_mb > $TRAFFIC_THRESHOLD_MB" | bc -l) )); then
            local details=$(get_network_interfaces)
            log_alert "HIGH NETWORK TRAFFIC" "${total_mb}MB" "${TRAFFIC_THRESHOLD_MB}MB" "$details"
        fi
    fi
}

main "$@"
