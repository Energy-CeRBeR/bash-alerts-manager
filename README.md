# Alert Manager

Система мониторинга ресурсов для Ubuntu с настраиваемыми алертами.

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

\`\`\`
alert-manager/
├── alert-manager.conf          # Конфигурационный файл
├── alert-manager.sh           # Главный скрипт запуска
├── README.md                  # Документация
├── INSTALL_WSL.md            # Инструкция для WSL
├── TROUBLESHOOTING.md        # Устранение проблем
├── PROJECT_ANALYSIS.md       # Подробный анализ проекта
├── scripts/
│   ├── install.sh            # Скрипт установки
│   ├── uninstall.sh          # Скрипт удаления
│   ├── test_runner.sh        # Тестовый запуск
│   ├── alert-manager.sh      # Основной мониторинг
│   ├── utils/                # Утилиты
│   │   ├── logger.sh         # Система логирования
│   │   ├── config_parser.sh  # Парсер конфигурации
│   │   ├── system_info.sh    # Информация о системе
│   │   └── alert_formatter.sh # Форматирование алертов
│   ├── observability/        # Модули мониторинга
│   │   ├── cpu_monitor.sh    # Мониторинг CPU
│   │   ├── ram_monitor.sh    # Мониторинг RAM
│   │   ├── disk_monitor.sh   # Мониторинг диска
│   │   └── process_monitor.sh # Мониторинг процессов
│   └── alerts/               # Система алертов
│       └── file_alert.sh     # Файловые алерты
└── logs/                     # Директория для логов (создается автоматически)
\`\`\`

chmod +x alert-manager.sh

# Дать права на выполнение всем скриптам в папке scripts
find scripts/ -name "*.sh" -exec chmod +x {} \;

# Проверить права
ls -la alert-manager.sh
ls -la scripts/
./scripts/install.sh --fix-permissions

## Быстрый старт

### 1. Установка

\`\`\`bash
# Клонируйте или скачайте проект
cd alert-manager

# Запустите установку
chmod +x scripts/install.sh
./scripts/install.sh
\`\`\`

### ⚠️ Решение проблемы "Permission denied"

Если получаете ошибку:
\`\`\`bash
./alert-manager.sh status
-bash: ./alert-manager.sh: Permission denied
\`\`\`

**Быстрое решение:**
\`\`\`bash
# Вариант 1: Автоматическое исправление
./scripts/install.sh --fix-permissions

# Вариант 2: Ручное исправление
chmod +x alert-manager.sh
find scripts/ -name "*.sh" -exec chmod +x {} \;

# Теперь можно запускать
./alert-manager.sh status
\`\`\`

### 2. Настройка

Отредактируйте `alert-manager.conf`:

\`\`\`bash
# Основные настройки
LOG_FILE="alerts.log"
CHECK_INTERVAL=1  # минуты

# Пороги мониторинга
CPU_THRESHOLD=80.0     # %
RAM_THRESHOLD=85.0     # %
DISK_THRESHOLD=90.0    # %
PROCESS_THRESHOLD=200  # количество

# Тестовый режим (низкие пороги)
TEST_MODE=true
TEST_CPU_THRESHOLD=10.0
TEST_RAM_THRESHOLD=20.0
TEST_DISK_THRESHOLD=30.0
TEST_PROCESS_THRESHOLD=50
\`\`\`

### 3. Тестирование

\`\`\`bash
# Проверьте статус
./alert-manager.sh status

# Запустите тест (с низкими порогами)
./alert-manager.sh test

# Посмотрите алерты
tail -50 alerts.log
\`\`\`

### 4. Установка в cron

\`\`\`bash
# Установить автоматический запуск
./alert-manager.sh install

# Проверить установку
./alert-manager.sh status
\`\`\`

## Команды

\`\`\`bash
./alert-manager.sh run        # Запустить мониторинг один раз
./alert-manager.sh install    # Установить cron job
./alert-manager.sh uninstall  # Удалить cron job
./alert-manager.sh status     # Показать статус
./alert-manager.sh test       # Тест с низкими порогами
./alert-manager.sh summary    # Сводка по алертам
./alert-manager.sh help       # Справка
\`\`\`

## Конфигурация

### Основные параметры

- `LOG_FILE` - файл для записи алертов
- `CHECK_INTERVAL` - интервал проверки в минутах
- `ENABLE_ALERTS` - включить/выключить алерты
- `ALERT_COOLDOWN` - пауза между одинаковыми алертами (минуты)

### Пороги мониторинга

- `CPU_THRESHOLD` - порог загрузки CPU (%)
- `RAM_THRESHOLD` - порог использования RAM (%)
- `DISK_THRESHOLD` - порог использования диска (%)
- `PROCESS_THRESHOLD` - максимальное количество процессов

### Тестовый режим

Установите `TEST_MODE=true` и настройте низкие пороги:
- `TEST_CPU_THRESHOLD=10.0`
- `TEST_RAM_THRESHOLD=20.0`
- `TEST_DISK_THRESHOLD=30.0`
- `TEST_PROCESS_THRESHOLD=50`

## Примеры алертов

\`\`\`
🚨 ALERT TRIGGERED 🚨
=====================
Timestamp: 2024-01-15 14:30:25
Alert Type: HIGH CPU USAGE
Current Value: 85.5%
Threshold: 80%
Status: CRITICAL

CPU Details:
-----------
CPU Model: Intel(R) Core(TM) i7-8700K CPU @ 3.70GHz
CPU Cores: 8
Load Average: 2.45, 1.89, 1.23

Top CPU Processes:
  PID  CPU  MEM  COMMAND
  1234 25.5 12.3 chrome
  5678 15.2 8.7  node
=====================
\`\`\`

## Установка в WSL

Подробная инструкция находится в файле `INSTALL_WSL.md`.

### Краткая версия:

\`\`\`bash
# 1. Подготовка WSL
sudo apt update && sudo apt upgrade -y
sudo apt install -y bc cron procps coreutils

# 2. Запуск cron в WSL
sudo service cron start
echo 'sudo service cron start' >> ~/.bashrc

# 3. Установка Alert Manager
./scripts/install.sh
./alert-manager.sh install

# 4. Тестирование
./alert-manager.sh test
cat alerts.log
\`\`\`

## Устранение неполадок

### Проблемы с правами доступа

\`\`\`bash
# Быстрое исправление
./scripts/install.sh --fix-permissions

# Или вручную
chmod +x alert-manager.sh
find scripts/ -name "*.sh" -exec chmod +x {} \;
\`\`\`

### Проблемы с cron

\`\`\`bash
# Проверьте статус cron
sudo service cron status

# Посмотрите логи cron
tail -f /var/log/syslog | grep cron

# Проверьте cron job
crontab -l
\`\`\`

### Отладка

\`\`\`bash
# Запустите с подробным выводом
bash -x ./alert-manager.sh run

# Проверьте конфигурацию
./alert-manager.sh status
\`\`\`

**📖 Полное руководство по устранению проблем:** `TROUBLESHOOTING.md`

## Расширение функциональности

### Добавление новых типов мониторинга

1. Создайте новый скрипт в `scripts/observability/`
2. Добавьте параметры в `alert-manager.conf`
3. Обновите `scripts/alert-manager.sh`

### Добавление новых способов уведомлений

1. Создайте новый скрипт в `scripts/alerts/`
2. Интегрируйте с `scripts/alerts/file_alert.sh`

## Документация

- `README.md` - основная документация (этот файл)
- `INSTALL_WSL.md` - подробная инструкция для WSL
- `TROUBLESHOOTING.md` - решение проблем
- `PROJECT_ANALYSIS.md` - техническая документация

## Лицензия

MIT License - используйте свободно для любых целей.
