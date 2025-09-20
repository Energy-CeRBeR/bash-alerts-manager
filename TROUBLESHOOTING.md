# Устранение проблем Alert Manager

## Проблема: Permission denied при запуске

### Симптомы
\`\`\`bash
./alert-manager.sh status
-bash: ./alert-manager.sh: Permission denied
\`\`\`

### Причина
Файлы скриптов не имеют прав на выполнение.

### Решение

#### Быстрое исправление:
\`\`\`bash
# Сделать главный скрипт исполняемым
chmod +x alert-manager.sh

# Сделать все скрипты исполняемыми
find scripts/ -name "*.sh" -exec chmod +x {} \;

# Теперь можно запускать
./alert-manager.sh status
\`\`\`

#### Автоматическое исправление:
\`\`\`bash
# Запустить скрипт установки, который исправит все права
chmod +x scripts/install.sh
./scripts/install.sh
\`\`\`

## Проблема: Cron не работает в WSL

### Симптомы
- Cron job установлен, но алерты не генерируются
- `sudo service cron status` показывает, что cron не запущен

### Решение
\`\`\`bash
# Запустить cron сервис
sudo service cron start

# Проверить статус
sudo service cron status

# Добавить автозапуск в ~/.bashrc
echo 'sudo service cron start' >> ~/.bashrc

# Или добавить в ~/.profile
echo 'sudo service cron start' >> ~/.profile
\`\`\`

## Проблема: Скрипты не находят файлы

### Симптомы
\`\`\`
ERROR: alert-manager.conf not found in current directory
\`\`\`

### Решение
\`\`\`bash
# Убедиться что находитесь в правильной директории
cd ~/alert-manager  # или где у вас проект

# Проверить наличие файлов
ls -la alert-manager.conf
ls -la alert-manager.sh

# Запускать скрипт из корневой директории проекта
./alert-manager.sh status
\`\`\`

## Проблема: Нет алертов в тестовом режиме

### Симптомы
- Скрипт запускается без ошибок
- Файл логов пустой или не создается

### Диагностика
\`\`\`bash
# Проверить конфигурацию
./alert-manager.sh status

# Запустить с отладкой
bash -x ./alert-manager.sh test

# Проверить права на запись
touch alerts.log
ls -la alerts.log
\`\`\`

### Решение
\`\`\`bash
# Убедиться что TEST_MODE включен
grep TEST_MODE alert-manager.conf

# Проверить тестовые пороги
grep TEST_ alert-manager.conf

# Запустить тест вручную
./alert-manager.sh test
\`\`\`

## Проблема: Отсутствуют зависимости

### Симптомы
\`\`\`
ERROR: Missing required dependencies: bc ps free df
\`\`\`

### Решение
\`\`\`bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y bc procps coreutils

# CentOS/RHEL
sudo yum install -y bc procps-ng coreutils

# Проверить установку
which bc ps free df
\`\`\`

## Проблема: Логи не создаются

### Симптомы
- Скрипт работает, но файл логов не появляется
- Ошибки записи в файл

### Решение
\`\`\`bash
# Проверить права на директорию
ls -la ./

# Создать файл логов вручную
touch alerts.log
chmod 664 alerts.log

# Проверить переменную LOG_FILE
grep LOG_FILE alert-manager.conf

# Запустить с полными правами
sudo ./alert-manager.sh test
\`\`\`

## Проблема: Высокая нагрузка от мониторинга

### Симптомы
- Система тормозит после установки
- Высокое потребление CPU от скриптов

### Решение
\`\`\`bash
# Увеличить интервал проверки
nano alert-manager.conf
# Изменить CHECK_INTERVAL=5 на CHECK_INTERVAL=10 или больше

# Переустановить cron job
./alert-manager.sh uninstall
./alert-manager.sh install

# Проверить нагрузку
top | grep alert-manager
\`\`\`

## Полезные команды для диагностики

\`\`\`bash
# Проверить все права доступа
find . -name "*.sh" -exec ls -la {} \;

# Проверить синтаксис всех скриптов
find scripts/ -name "*.sh" -exec bash -n {} \;

# Посмотреть логи cron
sudo tail -f /var/log/syslog | grep cron

# Проверить переменные окружения
env | grep -E "(PATH|HOME|USER)"

# Тест всех мониторов по отдельности
./scripts/observability/cpu_monitor.sh
./scripts/observability/ram_monitor.sh
./scripts/observability/disk_monitor.sh
./scripts/observability/process_monitor.sh

# Проверить системную информацию
./scripts/utils/system_info.sh
\`\`\`

## Контакты для поддержки

Если проблема не решается:
1. Проверьте все пункты выше
2. Запустите полную диагностику: `./scripts/test_runner.sh`
3. Соберите логи: `tar -czf debug.tar.gz *.log cron.log`
4. Опишите проблему с указанием версии системы: `uname -a`
\`\`\`

```bash file="" isHidden
