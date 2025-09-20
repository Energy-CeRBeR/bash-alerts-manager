#!/bin/bash

# Alert Manager Uninstallation Script
# ===================================
# Removes Alert Manager and cleans up system

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Remove cron jobs
remove_cron_jobs() {
    print_status "Removing cron jobs..."
    
    if crontab -l 2>/dev/null | grep -q "alert-manager"; then
        # Backup current crontab
        crontab -l > /tmp/crontab_backup_$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
        
        # Remove alert-manager entries
        crontab -l 2>/dev/null | grep -v "alert-manager" > /tmp/crontab_new || true
        crontab /tmp/crontab_new
        
        print_success "Cron jobs removed"
    else
        print_status "No cron jobs found"
    fi
}

# Remove systemd services
remove_systemd_services() {
    print_status "Checking for systemd services..."
    
    if [[ -f /etc/systemd/system/alert-manager.service ]]; then
        print_status "Removing systemd service..."
        sudo systemctl stop alert-manager.timer 2>/dev/null || true
        sudo systemctl disable alert-manager.timer 2>/dev/null || true
        sudo rm -f /etc/systemd/system/alert-manager.service
        sudo rm -f /etc/systemd/system/alert-manager.timer
        sudo systemctl daemon-reload
        print_success "Systemd services removed"
    else
        print_status "No systemd services found"
    fi
}

# Clean up temporary files
cleanup_temp_files() {
    print_status "Cleaning up temporary files..."
    
    # Remove temp files
    rm -f /tmp/alert_manager_cooldown
    rm -rf /tmp/alert_manager
    rm -f /tmp/crontab_new
    
    print_success "Temporary files cleaned"
}

# Backup logs and config
backup_data() {
    local backup_dir="$HOME/alert-manager-backup-$(date +%Y%m%d_%H%M%S)"
    
    print_status "Creating backup in $backup_dir..."
    
    mkdir -p "$backup_dir"
    
    # Backup configuration
    if [[ -f "$PROJECT_DIR/alert-manager.conf" ]]; then
        cp "$PROJECT_DIR/alert-manager.conf" "$backup_dir/"
    fi
    
    # Backup logs
    if [[ -f "$PROJECT_DIR/alerts.log" ]]; then
        cp "$PROJECT_DIR/alerts.log" "$backup_dir/"
    fi
    
    # Backup any other log files
    find "$PROJECT_DIR" -name "*.log" -exec cp {} "$backup_dir/" \; 2>/dev/null || true
    
    print_success "Backup created: $backup_dir"
}

# Show removal summary
show_summary() {
    print_status "Checking what will be removed..."
    
    echo ""
    echo "The following will be removed:"
    echo "=============================="
    
    # Check cron jobs
    if crontab -l 2>/dev/null | grep -q "alert-manager"; then
        echo "✓ Cron jobs related to alert-manager"
    fi
    
    # Check systemd services
    if [[ -f /etc/systemd/system/alert-manager.service ]]; then
        echo "✓ Systemd services (alert-manager.service, alert-manager.timer)"
    fi
    
    # Check temp files
    if [[ -f /tmp/alert_manager_cooldown ]] || [[ -d /tmp/alert_manager ]]; then
        echo "✓ Temporary files in /tmp"
    fi
    
    echo ""
    echo "The following will be preserved:"
    echo "==============================="
    echo "✓ Project files and scripts"
    echo "✓ Configuration file (alert-manager.conf)"
    echo "✓ Log files (will be backed up)"
    echo ""
}

# Main uninstallation function
main() {
    echo "Alert Manager Uninstallation"
    echo "============================"
    echo ""
    
    # Show what will be removed
    show_summary
    
    # Confirm removal
    read -p "Do you want to proceed with uninstallation? (y/N): " confirm
    if [[ "${confirm,,}" != "y" ]]; then
        print_status "Uninstallation cancelled"
        exit 0
    fi
    
    # Ask about backup
    read -p "Create backup of logs and configuration? (Y/n): " backup_confirm
    if [[ "${backup_confirm,,}" != "n" ]]; then
        backup_data
    fi
    
    # Perform removal
    remove_cron_jobs
    remove_systemd_services
    cleanup_temp_files
    
    echo ""
    print_success "Alert Manager uninstalled successfully!"
    echo ""
    echo "Note: Project files are still present in: $PROJECT_DIR"
    echo "To completely remove, delete the project directory manually."
    echo ""
    
    if [[ "${backup_confirm,,}" != "n" ]]; then
        echo "Your data has been backed up and can be found in:"
        echo "  $HOME/alert-manager-backup-*"
    fi
}

main "$@"
