#!/bin/bash

# Alert Manager - Главная точка входа
# ===================================
# Автор: Alert Manager System
# Описание: Главный скрипт для запуска системы мониторинга алертов

set -euo pipefail

# Получить директорию скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Проверить, что запускаем из правильной директории
if [[ ! -f "$SCRIPT_DIR/alert-manager.conf" ]]; then
    echo "ОШИБКА: alert-manager.conf не найден в текущей директории"
    echo "Пожалуйста, запустите этот скрипт из корневой директории alert-manager"
    exit 1
fi

# Загрузить конфигурацию
source "$SCRIPT_DIR/alert-manager.conf"

# Проверить зависимости
check_dependencies() {
    local missing_deps=()
    
    # Проверить необходимые команды
    for cmd in bc ps free df top uptime; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "ОШИБКА: Отсутствуют необходимые зависимости: ${missing_deps[*]}"
        echo "Пожалуйста, установите недостающие пакеты и попробуйте снова"
        exit 1
    fi
}

# Показать баннер
show_banner() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                              ALERT MANAGER                                   ║
║                         Инструмент мониторинга системы                       ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
}

# Показать информацию об использовании
show_usage() {
    cat << EOF
Использование: $0 [КОМАНДА] [ОПЦИИ]

Команды:
  run                    - Запустить проверки мониторинга один раз
  install               - Установить и настроить cron задачу
  uninstall            - Удалить cron задачу
  status               - Показать текущий статус и конфигурацию
  test                 - Запустить тест с низкими порогами
  summary              - Показать сводку алертов из лог файла
  help                 - Показать это сообщение помощи

Опции:
  --config FILE        - Использовать пользовательский файл конфигурации
  --verbose           - Включить подробный вывод
  --dry-run           - Показать что будет сделано без выполнения

Примеры:
  $0 run                          # Запустить мониторинг один раз
  $0 install                      # Настроить cron задачу
  $0 test                         # Тест с низкими порогами
  $0 status                       # Показать текущий статус
  $0 summary                      # Показать сводку алертов
EOF
}

# Показать текущий статус
show_status() {
    echo "Статус Alert Manager"
    echo "==================="
    echo ""
    
    # Статус конфигурации
    echo "Конфигурация:"
    echo "  Файл конфигурации: $SCRIPT_DIR/alert-manager.conf"
    echo "  Лог файл: ${LOG_FILE}"
    echo "  Интервал проверки: ${CHECK_INTERVAL} минут"
    echo "  Тестовый режим: ${TEST_MODE:-false}"
    echo ""
    
    # Пороги
    echo "Пороги мониторинга:"
    if [[ "${TEST_MODE:-false}" == "true" ]]; then
        echo "  CPU: ${TEST_CPU_THRESHOLD:-$CPU_THRESHOLD}% (ТЕСТОВЫЙ РЕЖИМ)"
        echo "  Память: ${TEST_RAM_THRESHOLD:-$RAM_THRESHOLD}% (ТЕСТОВЫЙ РЕЖИМ)"
        echo "  Диск: ${TEST_DISK_THRESHOLD:-$DISK_THRESHOLD}% (ТЕСТОВЫЙ РЕЖИМ)"
        echo "  Процессы: ${TEST_PROCESS_THRESHOLD:-$PROCESS_THRESHOLD} (ТЕСТОВЫЙ РЕЖИМ)"
    else
        echo "  CPU: ${CPU_THRESHOLD}%"
        echo "  Память: ${RAM_THRESHOLD}%"
        echo "  Диск: ${DISK_THRESHOLD}%"
        echo "  Процессы: ${PROCESS_THRESHOLD}"
    fi
    echo ""
    
    # Статус Cron
    echo "Статус Cron задачи:"
    if crontab -l 2>/dev/null | grep -q "alert-manager.sh"; then
        echo "  Статус: УСТАНОВЛЕНА"
        echo "  Расписание: $(crontab -l 2>/dev/null | grep "alert-manager.sh" | awk '{print $1, $2, $3, $4, $5}')"
    else
        echo "  Статус: НЕ УСТАНОВЛЕНА"
    fi
    echo ""
    
    # Статус лог файла
    echo "Статус лог файла:"
    if [[ -f "${LOG_FILE}" ]]; then
        echo "  Файл: СУЩЕСТВУЕТ"
        echo "  Размер: $(du -h "${LOG_FILE}" | cut -f1)"
        echo "  Последнее изменение: $(stat -c %y "${LOG_FILE}" 2>/dev/null | cut -d. -f1)"
        echo "  Количество алертов: $(grep -c "🚨 ALERT TRIGGERED 🚨" "${LOG_FILE}" 2>/dev/null || echo "0")"
    else
        echo "  Файл: НЕ СУЩЕСТВУЕТ"
    fi
}

# Установить cron задачу
install_cron() {
    local cron_schedule="*/${CHECK_INTERVAL} * * * *"
    local cron_command="$SCRIPT_DIR/alert-manager.sh run >> $SCRIPT_DIR/cron.log 2>&1"
    
    echo "Установка cron задачи Alert Manager..."
    echo "Расписание: Каждые ${CHECK_INTERVAL} минут"
    echo "Команда: $cron_command"
    
    # Резервная копия существующего crontab
    crontab -l > /tmp/crontab_backup 2>/dev/null || true
    
    # Удалить существующие записи alert-manager
    crontab -l 2>/dev/null | grep -v "alert-manager.sh" > /tmp/crontab_new || true
    
    # Добавить новую запись
    echo "$cron_schedule $cron_command" >> /tmp/crontab_new
    
    # Установить новый crontab
    crontab /tmp/crontab_new
    
    echo "✅ Cron задача установлена успешно!"
    echo "Alert manager будет запускаться каждые ${CHECK_INTERVAL} минут."
    echo "Логи будут записываться в: $SCRIPT_DIR/cron.log"
}

# Удалить cron задачу
uninstall_cron() {
    echo "Удаление cron задачи Alert Manager..."
    
    # Удалить записи alert-manager из crontab
    crontab -l 2>/dev/null | grep -v "alert-manager.sh" > /tmp/crontab_new || true
    crontab /tmp/crontab_new
    
    echo "✅ Cron задача удалена успешно!"
}

# Запустить мониторинг
run_monitoring() {
    echo "Запуск мониторинга Alert Manager..."
    
    # Сделать скрипты исполняемыми
    chmod +x "$SCRIPT_DIR/scripts/alert-manager.sh"
    chmod +x "$SCRIPT_DIR/scripts/observability/"*.sh
    chmod +x "$SCRIPT_DIR/scripts/alerts/"*.sh
    
    # Запустить главный скрипт мониторинга
    "$SCRIPT_DIR/scripts/alert-manager.sh"
    
    echo "Мониторинг завершен."
}

# Запустить тестовый режим
run_test() {
    echo "Запуск Alert Manager в ТЕСТОВОМ РЕЖИМЕ..."
    echo "Использование низких порогов для срабатывания алертов при тестировании..."
    
    # Временно включить тестовый режим
    local original_test_mode="${TEST_MODE:-false}"
    export TEST_MODE=true
    
    run_monitoring
    
    # Восстановить оригинальный тестовый режим
    export TEST_MODE="$original_test_mode"
    
    echo ""
    echo "Тест завершен! Проверьте лог файл на наличие алертов:"
    echo "  Лог файл: ${LOG_FILE}"
    echo "  Просмотр алертов: tail -50 '${LOG_FILE}'"
}

# Показать сводку алертов
show_summary() {
    if [[ -f "$SCRIPT_DIR/scripts/alerts/file_alert.sh" ]]; then
        "$SCRIPT_DIR/scripts/alerts/file_alert.sh" summary "${LOG_FILE}"
    else
        echo "Скрипт сводки алертов не найден"
        exit 1
    fi
}

# Главная функция
main() {
    local command="${1:-help}"
    
    # Разбор опций
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
                echo "РЕЖИМ ПРОБНОГО ЗАПУСКА - Изменения не будут внесены"
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Обновить команду после разбора опций
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

# Выполнить главную функцию
main "$@"
