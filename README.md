# Alert Manager

Система мониторинга ресурсов для Ubuntu с настраиваемыми алертами

## Возможности

- 🖥️ **Мониторинг CPU** - отслеживание загрузки процессора
- 💾 **Мониторинг RAM** - контроль использования оперативной памяти  
- 💿 **Мониторинг диска** - проверка свободного места
- 🔄 **Мониторинг процессов** - подсчет количества запущенных процессов
- 📝 **Красивые логи** - подробные алерты с временными метками
- ⚙️ **Настраиваемые пороги** - гибкая конфигурация через файл
- 🕐 **Автоматический запуск** - интеграция с cron
- 🧪 **Тестовый режим** - низкие пороги для проверки работы

## Структура проекта

```bash
alert-manager/
├── alert-manager.conf         # Конфигурационный файл
├── alert-manager.sh           # Главный скрипт запуска
├── README.md                  # Документация
├── scripts/                   # Директория для всех скриптов
│   ├── install.sh             # Скрипт установки
│   ├── uninstall.sh           # Скрипт удаления
│   ├── test_runner.sh         # Тестовый запуск
│   ├── alert-manager.sh       # Основной мониторинг
│   ├── utils/                 # Утилиты
│   │   ├── logger.sh          # Система логирования
│   │   ├── config_parser.sh   # Парсер конфигурации
│   │   ├── system_info.sh     # Информация о системе
│   │   └── alert_formatter.sh # Форматирование алертов
│   ├── observability/         # Модули мониторинга
│   │   ├── cpu_monitor.sh     # Мониторинг CPU
│   │   ├── ram_monitor.sh     # Мониторинг RAM
│   │   ├── disk_monitor.sh    # Мониторинг диска
│   │   └── process_monitor.sh # Мониторинг процессов
│   └── alerts/                # Система алертов
│       └── file_alert.sh      # Файловые алерты
└── alerts.log                 # Файл с логами
```

# Быстрый старт

## Настройка окружения

**Если используете `wsl`, то запустите**:

```powershell
wsl
```

**Установите нужные зависимости**:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y bc cron procps coreutils
```

## Клонирование репозитория

```bash
git clone https://github.com/Energy-CeRBeR/bash-alerts-manager.git
cd bash-alerts-manager
```

## Установка нужных прав для корректной работы менеджера

```bash
chmod +x alert-manager.sh
find scripts/ -name "*.sh" -exec chmod +x {} \;
```

**Проверка:**

Команда `./alert-manager.sh status` не должна выдавать `-bash: ./alert-manager.sh: Permission denied`

## Настройка проекта

Отредактируйте под себя `alert-manager.conf`:

## Команды

```bash
./alert-manager.sh run        # Запустить мониторинг один раз
./alert-manager.sh install    # Установить cron job
./alert-manager.sh uninstall  # Удалить cron job
./alert-manager.sh status     # Показать статус
./alert-manager.sh test       # Тест с низкими порогами
./alert-manager.sh summary    # Сводка по алертам
./alert-manager.sh help       # Справка
```

## Примеры алертов

```
🚨 ALERT TRIGGERED 🚨
=====================

Timestamp: 2024-01-15 14:30:25
Alert Type: HIGH CPU USAGE
Current Value: 85.5%
Threshold: 80%
Status: CRITICAL

CPU Details
-----------

CPU Model: Intel(R) Core(TM) i7-8700K CPU @ 3.70GHz
CPU Cores: 8
Load Average: 2.45, 1.89, 1.23

Top CPU Processes:
  PID  CPU  MEM  COMMAND
  1234 25.5 12.3 chrome
  5678 15.2 8.7  node
=====================
```

## Расширение функциональности

### Добавление новых типов мониторинга

1. Создайте новый скрипт в `scripts/observability/`
2. Добавьте параметры в `alert-manager.conf`
3. Обновите `scripts/alert-manager.sh`

### Добавление новых способов уведомлений

1. Создайте новый скрипт в `scripts/alerts/`
2. Интегрируйте с `scripts/alerts/file_alert.sh`

## Запуск скрипта по крону

> В разработке...
