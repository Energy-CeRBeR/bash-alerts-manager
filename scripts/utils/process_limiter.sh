#!/bin/bash

# Process Limiter
# ===============
# Ограничивает запуск новых процессов при превышении лимита

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
export PROJECT_DIR

CONFIG_FILE="$PROJECT_DIR/alert-manager.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

source "$SCRIPT_DIR/logger.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' 

get_user_process_count() {
    local username=$(whoami)
    local count=$(ps -u "$username" | wc -l)
    echo $((count - 1))
}

get_process_limit() {
    if [[ "${TEST_MODE:-false}" == "true" ]]; then
        echo "${TEST_PROCESS_THRESHOLD:-50}"
    else
        echo "${PROCESS_THRESHOLD:-200}"
    fi
}

check_process_limit() {
    local current_count=$(get_user_process_count)
    local limit=$(get_process_limit)
    local username=$(whoami)
    
    if (( current_count >= limit )); then
        echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  ⛔ ОШИБКА: ПРЕВЫШЕН ЛИМИТ ПРОЦЕССОВ                      ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${YELLOW}Пользователь:${NC}      $username"
        echo -e "${YELLOW}Текущих процессов:${NC} $current_count"
        echo -e "${YELLOW}Максимум:${NC}          $limit"
        echo ""
        echo -e "${RED}Запуск нового процесса ЗАПРЕЩЕН!${NC}"
        echo ""
        echo -e "${YELLOW}Рекомендации:${NC}"
        echo "  1. Завершите ненужные процессы командой: kill <PID>"
        echo "  2. Посмотрите список процессов: ps -u $username"
        echo "  3. Увеличьте лимит в файле: $CONFIG_FILE"
        echo ""
        
        log_alert "PROCESS LIMIT EXCEEDED" "$current_count" "$limit" "Попытка запуска процесса заблокирована для пользователя $username"
        
        return 1
    else
        local remaining=$((limit - current_count))
        echo -e "${GREEN}✓ Проверка пройдена${NC}"
        echo -e "  Процессов: ${current_count}/${limit} (осталось: ${remaining})"
        return 0
    fi
}

run_with_limit() {
    if [[ $# -eq 0 ]]; then
        echo -e "${RED}Ошибка: не указана команда для запуска${NC}"
        echo "Использование: $0 <команда> [аргументы...]"
        return 1
    fi
    
    echo -e "${YELLOW}Проверка лимита процессов...${NC}"
    echo ""
    
    if check_process_limit; then
        echo ""
        echo -e "${GREEN}Запуск команды:${NC} $*"
        echo ""
        exec "$@"
    else
        return 1
    fi
}

show_status() {
    local current_count=$(get_user_process_count)
    local limit=$(get_process_limit)
    local username=$(whoami)
    local percentage=$((current_count * 100 / limit))
    
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  Статус лимита процессов                                  ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Пользователь:${NC}      $username"
    echo -e "${YELLOW}Текущих процессов:${NC} $current_count"
    echo -e "${YELLOW}Максимум:${NC}          $limit"
    echo -e "${YELLOW}Использовано:${NC}      ${percentage}%"
    echo ""
    
    if (( percentage >= 90 )); then
        echo -e "${RED}⚠ КРИТИЧЕСКИЙ УРОВЕНЬ! Осталось мало места для новых процессов${NC}"
    elif (( percentage >= 75 )); then
        echo -e "${YELLOW}⚠ ПРЕДУПРЕЖДЕНИЕ: Приближаетесь к лимиту${NC}"
    else
        echo -e "${GREEN}✓ Нормальный уровень${NC}"
    fi
    echo ""
    
    echo -e "${YELLOW}Топ-5 процессов по памяти:${NC}"
    ps -u "$username" --sort=-%mem -o pid,comm,%mem,%cpu | head -6
}

main() {
    case "${1:-}" in
        --check|-c)
            check_process_limit
            ;;
        --status|-s)
            show_status
            ;;
        --help|-h)
            cat << EOF
Process Limiter - Ограничитель запуска процессов

Использование:
  $0 --check              Проверить текущий лимит
  $0 --status             Показать статус использования
  $0 --help               Показать эту справку
  $0 <команда> [args...]  Запустить команду с проверкой лимита

Примеры:
  $0 --check
  $0 --status
  $0 sleep 100
  $0 python script.py
  $0 bash -c "while true; do echo test; sleep 1; done"

Конфигурация:
  Файл: $CONFIG_FILE
  Параметры: PROCESS_THRESHOLD, TEST_PROCESS_THRESHOLD
EOF
            ;;
        "")
            echo -e "${RED}Ошибка: не указана команда${NC}"
            echo "Используйте --help для справки"
            return 1
            ;;
        *)
            run_with_limit "$@"
            ;;
    esac
}

main "$@"
