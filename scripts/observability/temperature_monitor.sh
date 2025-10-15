#!/bin/bash

# Temperature Monitor
# ===================
# Мониторит температуру CPU/GPU и генерирует алерты

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
export PROJECT_DIR

CONFIG_FILE="$PROJECT_DIR/alert-manager.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

source "$SCRIPT_DIR/../utils/logger.sh"

THRESHOLD=${1:-75}

# Получить температуру CPU
get_cpu_temperature() {
    local temp=""
    
    # Метод 1: Использование sensors (lm-sensors)
    if command -v sensors &> /dev/null; then
        temp=$(sensors 2>/dev/null | grep -i "Core 0" | awk '{print $3}' | sed 's/+//;s/°C//' | head -1)
    fi
    
    # Метод 2: Чтение из /sys/class/thermal
    if [[ -z "$temp" ]] || [[ "$temp" == "0" ]]; then
        if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
            local temp_millidegrees=$(cat /sys/class/thermal/thermal_zone0/temp)
            temp=$(echo "scale=1; $temp_millidegrees / 1000" | bc)
        fi
    fi
    
    # Метод 3: Использование /proc/acpi (старые системы)
    if [[ -z "$temp" ]] || [[ "$temp" == "0" ]]; then
        if [[ -f /proc/acpi/thermal_zone/THM0/temperature ]]; then
            temp=$(cat /proc/acpi/thermal_zone/THM0/temperature | awk '{print $2}')
        fi
    fi
    
    echo "${temp:-N/A}"
}

# Получить все доступные температурные зоны
get_all_temperatures() {
    cat << EOF
Температурные зоны:
------------------
EOF
    
    # Показать все thermal zones
    if [[ -d /sys/class/thermal ]]; then
        for zone in /sys/class/thermal/thermal_zone*/; do
            if [[ -f "${zone}temp" ]] && [[ -f "${zone}type" ]]; then
                local zone_type=$(cat "${zone}type")
                local zone_temp=$(cat "${zone}temp")
                local temp_celsius=$(echo "scale=1; $zone_temp / 1000" | bc)
                echo "  ${zone_type}: ${temp_celsius}°C"
            fi
        done
    fi
    
    # Показать sensors если доступен
    if command -v sensors &> /dev/null; then
        echo ""
        echo "Детальная информация (sensors):"
        sensors 2>/dev/null | grep -E "Core|temp|fan" | sed 's/^/  /'
    fi
}

# Получить информацию о системе охлаждения
get_cooling_info() {
    cat << EOF

Информация о охлаждении:
-----------------------
EOF
    
    # Проверить вентиляторы
    if command -v sensors &> /dev/null; then
        local fans=$(sensors 2>/dev/null | grep -i "fan" || echo "Информация о вентиляторах недоступна")
        echo "$fans" | sed 's/^/  /'
    fi
    
    # Проверить политику охлаждения
    if [[ -d /sys/class/thermal/cooling_device0 ]]; then
        echo ""
        echo "Устройства охлаждения:"
        for device in /sys/class/thermal/cooling_device*/; do
            if [[ -f "${device}type" ]]; then
                local dev_type=$(cat "${device}type")
                local cur_state=$(cat "${device}cur_state" 2>/dev/null || echo "N/A")
                local max_state=$(cat "${device}max_state" 2>/dev/null || echo "N/A")
                echo "  ${dev_type}: ${cur_state}/${max_state}"
            fi
        done
    fi
}

# Основная логика мониторинга
main() {
    local current_temp=$(get_cpu_temperature)
    
    # Проверка доступности данных о температуре
    if [[ "$current_temp" == "N/A" ]]; then
        log_info "Temperature Check - Данные о температуре недоступны. Установите lm-sensors: sudo apt install lm-sensors && sudo sensors-detect"
        return 0
    fi
    
    log_info "Temperature Check - Current: ${current_temp}°C, Threshold: ${THRESHOLD}°C"
    
    # Сравнение с порогом
    if (( $(echo "$current_temp > $THRESHOLD" | bc -l) )); then
        local details=$(get_all_temperatures)
        details="${details}\n$(get_cooling_info)"
        log_alert "HIGH TEMPERATURE" "${current_temp}°C" "${THRESHOLD}°C" "$details"
    fi
}

main "$@"
