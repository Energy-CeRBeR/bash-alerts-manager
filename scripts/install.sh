#!/bin/bash

# Alert Manager Installation Script
# =================================
# Automated installation and setup script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_requirements() {
    print_status "Checking system requirements..."
    
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot determine OS version"
        exit 1
    fi
    
    local os_name=$(grep '^NAME=' /etc/os-release | cut -d'"' -f2)
    print_status "Detected OS: $os_name"
    
    local missing_commands=()
    for cmd in bash bc ps free df top uptime crontab; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        print_error "Missing required commands: ${missing_commands[*]}"
        print_status "Installing missing packages..."
        
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y bc procps coreutils cron
        elif command -v yum &> /dev/null; then
            sudo yum install -y bc procps-ng coreutils cronie
        else
            print_error "Cannot install missing packages automatically"
            print_error "Please install: ${missing_commands[*]}"
            exit 1
        fi
    fi
    
    print_success "System requirements satisfied"
}

setup_directories() {
    print_status "Setting up directory structure..."
    
    mkdir -p "$PROJECT_DIR/logs"
    mkdir -p "$PROJECT_DIR/backup"
    mkdir -p "/tmp/alert_manager"
    
    print_success "Directory structure created"
}

set_permissions() {
    print_status "Setting file permissions..."
    
    chmod +x "$PROJECT_DIR/alert-manager.sh"
    
    find "$PROJECT_DIR/scripts" -name "*.sh" -exec chmod +x {} \;
    
    chmod 644 "$PROJECT_DIR/alert-manager.conf"
    
    mkdir -p "$PROJECT_DIR/logs"
    chmod 755 "$PROJECT_DIR/logs"
    
    chown -R "$(whoami):$(whoami)" "$PROJECT_DIR"
    
    print_success "Permissions set correctly"
}

create_systemd_service() {
    if [[ "$1" == "yes" ]]; then
        print_status "Creating systemd service..."
        
        cat > /tmp/alert-manager.service << EOF
[Unit]
Description=Alert Manager System Monitor
After=network.target

[Service]
Type=oneshot
User=$(whoami)
WorkingDirectory=$PROJECT_DIR
ExecStart=$PROJECT_DIR/alert-manager.sh run
StandardOutput=append:$PROJECT_DIR/logs/systemd.log
StandardError=append:$PROJECT_DIR/logs/systemd.log

[Install]
WantedBy=multi-user.target
EOF
        
        cat > /tmp/alert-manager.timer << EOF
[Unit]
Description=Run Alert Manager every few minutes
Requires=alert-manager.service

[Timer]
OnCalendar=*:0/\${CHECK_INTERVAL:-5}
Persistent=true

[Install]
WantedBy=timers.target
EOF
        
        print_status "Systemd service files created in /tmp/"
        print_status "To install: sudo cp /tmp/alert-manager.* /etc/systemd/system/"
        print_status "Then run: sudo systemctl enable --now alert-manager.timer"
    fi
}

run_tests() {
    print_status "Running installation tests..."
    
    if source "$PROJECT_DIR/alert-manager.conf"; then
        print_success "Configuration file loads correctly"
    else
        print_error "Configuration file has errors"
        exit 1
    fi
    
    if "$PROJECT_DIR/alert-manager.sh" status &> /dev/null; then
        print_success "Main script executes correctly"
    else
        print_error "Main script has errors"
        exit 1
    fi
    
    print_success "All tests passed"
}

main() {
    echo "Alert Manager Installation"
    echo "========================="
    echo ""
    
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root. Consider running as regular user."
    fi
    
    check_requirements
    setup_directories
    set_permissions
    
    read -p "Create systemd service files? (y/N): " create_service
    create_systemd_service "${create_service,,}"
    
    run_tests
    
    echo ""
    print_success "Installation completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Review configuration: $PROJECT_DIR/alert-manager.conf"
    echo "2. Test the system: $PROJECT_DIR/alert-manager.sh test"
    echo "3. Install cron job: $PROJECT_DIR/alert-manager.sh install"
    echo "4. Check status: $PROJECT_DIR/alert-manager.sh status"
    echo ""
    echo "If you get 'Permission denied' errors:"
    echo "  Run: ./scripts/install.sh --fix-permissions"
    echo "  Or manually: chmod +x alert-manager.sh"
    echo ""
    echo "For help: $PROJECT_DIR/alert-manager.sh help"
    echo "Troubleshooting guide: $PROJECT_DIR/TROUBLESHOOTING.md"
}

main "$@"
