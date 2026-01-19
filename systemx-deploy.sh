#!/bin/bash
# SYSTEM-X PUBLIC DEPLOYMENT SCRIPT
# Version 1.4.0 (15012026)
# Standalone deployment script for System-X installation management
# Copyright (C) 2021-2026 Shane Daley, M0VUB <shane@freestar.network>

set -e
trap 'cleanup_on_exit' EXIT

################################################################################
# Color Codes and Constants
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

REPO_URL="https://github.com/ShaYmez/System-X-Installer.git"
REPO_OWNER="ShaYmez"
REPO_NAME="System-X-Installer"
GITHUB_API="https://api.github.com"

WORK_DIR="/opt/tmp/systemx-deploy"
INSTALL_DIR="/opt/RYSEN"
CONFIG_DIR="/etc/rysen"

GITHUB_TOKEN=""
TOKEN_VALIDATED=false

################################################################################
# Cleanup Function
################################################################################

cleanup_on_exit() {
    # Overwrite token in memory
    if [ -n "$GITHUB_TOKEN" ]; then
        GITHUB_TOKEN=$(head -c 100 /dev/zero | tr '\0' 'X' 2>/dev/null || echo "")
        unset GITHUB_TOKEN
    fi
}

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo ""
    echo -e "${CYAN}================================================================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}================================================================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

press_enter() {
    echo ""
    read -p "Press Enter to continue..."
}

################################################################################
# System Checks
################################################################################

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

check_os() {
    if [ ! -f /etc/os-release ]; then
        print_error "Cannot detect operating system"
        exit 1
    fi
    
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
    
    # Check for supported OS
    if [ "$OS" = "debian" ]; then
        VERSION=$(sed 's/\..*//' /etc/debian_version 2>/dev/null)
        if [ "$VERSION" != "11" ] && [ "$VERSION" != "12" ] && [ "$VERSION" != "13" ]; then
            print_error "Only Debian 11, 12, and 13 are supported"
            print_error "Detected: Debian $VERSION"
            exit 1
        fi
        print_info "Detected: Debian $VERSION"
    elif [ "$OS" = "ubuntu" ]; then
        if [ "$OS_VERSION" != "22.04" ] && [ "$OS_VERSION" != "24.04" ]; then
            print_error "Only Ubuntu 22.04 LTS and 24.04 LTS are supported"
            print_error "Detected: Ubuntu $OS_VERSION"
            exit 1
        fi
        print_info "Detected: Ubuntu $OS_VERSION LTS"
    else
        print_error "Only Debian and Ubuntu distributions are supported"
        print_error "Detected: $OS"
        exit 1
    fi
}

check_network() {
    print_info "Testing network connectivity..."
    
    # Test GitHub connectivity
    if ! curl -s --connect-timeout 5 https://github.com > /dev/null 2>&1; then
        print_warning "Cannot reach github.com"
        return 1
    fi
    
    # Test GitHub API
    if ! curl -s --connect-timeout 5 ${GITHUB_API} > /dev/null 2>&1; then
        print_warning "Cannot reach GitHub API"
        return 1
    fi
    
    print_success "Network connectivity OK"
    return 0
}

################################################################################
# Token Management
################################################################################

validate_token_format() {
    local token="$1"
    
    # Validate token format (ghp_* with 40 chars total, or github_pat_* with variable length)
    if [[ "$token" =~ ^(ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{82})$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_token_api() {
    local token="$1"
    
    print_info "Validating token with GitHub API..."
    
    # Test token against GitHub API
    local response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "${GITHUB_API}/user" \
        --connect-timeout 10 \
        --max-time 30)
    
    if [ "$response" = "200" ]; then
        # Get username
        local username=$(curl -s \
            -H "Authorization: token $token" \
            -H "Accept: application/vnd.github.v3+json" \
            "${GITHUB_API}/user" | grep -o '"login":"[^"]*' | cut -d'"' -f4)
        
        print_success "Token valid for user: $username"
        
        # Test repository access
        response=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Authorization: token $token" \
            -H "Accept: application/vnd.github.v3+json" \
            "${GITHUB_API}/repos/${REPO_OWNER}/${REPO_NAME}" \
            --connect-timeout 10 \
            --max-time 30)
        
        if [ "$response" = "200" ]; then
            print_success "Repository access confirmed"
            return 0
        else
            print_error "Cannot access repository (HTTP $response)"
            print_error "Token may not have required 'repo' permissions"
            return 1
        fi
    elif [ "$response" = "401" ] || [ "$response" = "403" ]; then
        print_error "Token validation failed (HTTP $response)"
        print_error "Token is invalid or expired"
        return 1
    else
        print_warning "Unexpected response (HTTP $response)"
        return 1
    fi
}

prompt_token() {
    print_header "GitHub Personal Access Token Required"
    
    echo "System-X requires a GitHub Personal Access Token (PAT) for installation."
    echo ""
    echo "Token Requirements:"
    echo "  - Format: ghp_xxxx... or github_pat_xxxx..."
    echo "  - Scope: 'repo' access to the System-X installation repository"
    echo "  - Provided by System-X Admin Team"
    echo ""
    echo "If you don't have a token, please contact your System-X administrator."
    echo ""
    
    while true; do
        read -s -p "Enter GitHub token: " GITHUB_TOKEN
        echo ""
        
        if [ -z "$GITHUB_TOKEN" ]; then
            print_error "Token cannot be empty"
            echo ""
            read -p "Try again? (y/n): " retry
            if [ "$retry" != "y" ] && [ "$retry" != "Y" ]; then
                return 1
            fi
            continue
        fi
        
        # Validate format
        if ! validate_token_format "$GITHUB_TOKEN"; then
            print_error "Invalid token format"
            echo "Expected: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
            echo "      or: github_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
            echo ""
            read -p "Try again? (y/n): " retry
            if [ "$retry" != "y" ] && [ "$retry" != "Y" ]; then
                return 1
            fi
            continue
        fi
        
        # Validate with API
        if validate_token_api "$GITHUB_TOKEN"; then
            TOKEN_VALIDATED=true
            export GITHUB_TOKEN
            return 0
        else
            echo ""
            read -p "Try again? (y/n): " retry
            if [ "$retry" != "y" ] && [ "$retry" != "Y" ]; then
                return 1
            fi
        fi
    done
}

################################################################################
# Installation Functions
################################################################################

install_systemx() {
    print_header "System-X Fresh Installation"
    
    # Check if already installed
    if [ -d "$CONFIG_DIR" ] && [ -f "$CONFIG_DIR/rysen.cfg" ]; then
        print_warning "System-X appears to be already installed"
        echo ""
        read -p "Do you want to reinstall? This will create a backup first. (y/n): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            print_info "Installation cancelled"
            press_enter
            return
        fi
        
        # Create backup before reinstalling
        backup_installation
    fi
    
    print_info "Preparing installation..."
    
    # Create work directory
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
    
    # Clone repository
    print_info "Cloning System-X repository..."
    
    if [ "$TOKEN_VALIDATED" = true ] && [ -n "$GITHUB_TOKEN" ]; then
        # Use token for cloning
        if ! git clone "https://${GITHUB_TOKEN}@github.com/${REPO_OWNER}/${REPO_NAME}.git" systemx-installer 2>/dev/null; then
            print_error "Failed to clone repository"
            press_enter
            return
        fi
    else
        # Try public clone
        if ! git clone "$REPO_URL" systemx-installer 2>/dev/null; then
            print_error "Failed to clone repository"
            print_info "Repository may require authentication"
            press_enter
            return
        fi
    fi
    
    cd systemx-installer
    
    print_success "Repository cloned successfully"
    
    # Make installer executable
    chmod +x systemx-docker-install.sh
    
    print_info "Starting System-X installer..."
    echo ""
    
    # Run installer with token in environment
    if [ "$TOKEN_VALIDATED" = true ] && [ -n "$GITHUB_TOKEN" ]; then
        export GITHUB_TOKEN
        ./systemx-docker-install.sh
    else
        ./systemx-docker-install.sh
    fi
    
    echo ""
    print_success "Installation completed"
    
    # Cleanup
    cd /
    rm -rf "$WORK_DIR"
    
    press_enter
}

upgrade_systemx() {
    print_header "System-X Upgrade"
    
    # Check if System-X is installed
    if [ ! -d "$CONFIG_DIR" ] || [ ! -f "$CONFIG_DIR/rysen.cfg" ]; then
        print_error "System-X is not installed"
        print_info "Use option [1] to install System-X first"
        press_enter
        return
    fi
    
    # Check if systemx-upgrade command exists
    if [ ! -x /usr/local/sbin/systemx-upgrade ]; then
        print_error "Upgrade command not found"
        print_error "Your installation may be incomplete or from an older version"
        press_enter
        return
    fi
    
    print_info "Starting System-X upgrade process..."
    echo ""
    
    # Run the upgrade command
    /usr/local/sbin/systemx-upgrade
    
    echo ""
    print_success "Upgrade process completed"
    
    press_enter
}

uninstall_systemx() {
    print_header "System-X Uninstallation"
    
    # Check if System-X is installed
    if [ ! -d "$CONFIG_DIR" ]; then
        print_error "System-X is not installed"
        press_enter
        return
    fi
    
    # Check if uninstall command exists
    if [ ! -x /usr/local/sbin/systemx-uninstall ]; then
        print_error "Uninstall command not found"
        print_error "Your installation may be incomplete or from an older version"
        press_enter
        return
    fi
    
    print_warning "This will completely remove System-X from your system"
    print_info "A backup will be created automatically"
    echo ""
    
    # Run the uninstall command
    /usr/local/sbin/systemx-uninstall
    
    press_enter
}

################################################################################
# Utilities
################################################################################

utilities_menu() {
    while true; do
        print_header "System-X Utilities"
        
        echo "1) Backup System-X Configuration"
        echo "2) Restore from Backup"
        echo "3) View System Logs"
        echo "4) Check Docker Status"
        echo "5) Network Diagnostics"
        echo "6) Disk Usage Report"
        echo "7) Register Installation"
        echo "8) Migrate from v1.3.x"
        echo "9) Back to Main Menu"
        echo ""
        read -p "Select option [1-9]: " choice
        
        case $choice in
            1)
                backup_installation
                ;;
            2)
                restore_backup
                ;;
            3)
                view_logs
                ;;
            4)
                docker_status
                ;;
            5)
                network_diagnostics
                ;;
            6)
                disk_usage
                ;;
            7)
                register_installation
                ;;
            8)
                migrate_from_v13
                ;;
            9)
                return
                ;;
            *)
                print_error "Invalid option"
                press_enter
                ;;
        esac
    done
}

backup_installation() {
    print_header "Backup System-X Configuration"
    
    if [ ! -d "$CONFIG_DIR" ]; then
        print_error "System-X is not installed"
        press_enter
        return
    fi
    
    local backup_dir="/opt/backups"
    local backup_name="systemx-backup-$(date +%Y%m%d-%H%M%S)"
    local backup_path="$backup_dir/$backup_name"
    
    mkdir -p "$backup_dir"
    mkdir -p "$backup_path"
    
    print_info "Creating backup..."
    
    # Backup configuration
    if [ -d "$CONFIG_DIR" ]; then
        cp -a "$CONFIG_DIR" "$backup_path/config" 2>/dev/null || true
        print_success "Configuration backed up"
    fi
    
    # Backup logs
    if [ -d "/var/log/rysen" ]; then
        cp -a "/var/log/rysen" "$backup_path/logs" 2>/dev/null || true
        print_success "Logs backed up"
    fi
    
    # Create manifest
    cat > "$backup_path/MANIFEST.txt" <<EOF
System-X Backup Manifest
========================
Created: $(date)
Hostname: $(hostname)

Contents:
- Configuration files: $CONFIG_DIR
- Log files: /var/log/rysen

Restore Instructions:
1. Stop System-X services: systemx-stop (or docker compose down)
2. Restore configuration: cp -a $backup_path/config/* $CONFIG_DIR/
3. Restore logs: cp -a $backup_path/logs/* /var/log/rysen/
4. Start System-X services: systemx-start (or docker compose up -d)
EOF
    
    # Create tarball
    cd "$backup_dir"
    tar -czf "${backup_name}.tar.gz" "$backup_name" 2>/dev/null || true
    rm -rf "$backup_name"
    
    print_success "Backup created: ${backup_path}.tar.gz"
    
    press_enter
}

restore_backup() {
    print_header "Restore from Backup"
    
    local backup_dir="/opt/backups"
    
    if [ ! -d "$backup_dir" ]; then
        print_error "No backups found"
        press_enter
        return
    fi
    
    print_info "Available backups:"
    echo ""
    
    local backups=($(ls -1 "$backup_dir"/*.tar.gz 2>/dev/null || true))
    
    if [ ${#backups[@]} -eq 0 ]; then
        print_error "No backups found"
        press_enter
        return
    fi
    
    local i=1
    for backup in "${backups[@]}"; do
        echo "$i) $(basename "$backup")"
        i=$((i+1))
    done
    
    echo ""
    read -p "Select backup to restore [1-${#backups[@]}] or 0 to cancel: " choice
    
    if [ "$choice" -eq 0 ] 2>/dev/null; then
        print_info "Restore cancelled"
        press_enter
        return
    fi
    
    if [ "$choice" -lt 1 ] || [ "$choice" -gt ${#backups[@]} ] 2>/dev/null; then
        print_error "Invalid selection"
        press_enter
        return
    fi
    
    local selected_backup="${backups[$((choice-1))]}"
    
    print_warning "This will restore from: $(basename "$selected_backup")"
    read -p "Continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Restore cancelled"
        press_enter
        return
    fi
    
    print_info "Extracting backup..."
    cd "$backup_dir"
    tar -xzf "$selected_backup"
    
    local backup_name=$(basename "$selected_backup" .tar.gz)
    
    print_info "Stopping System-X services..."
    if [ -x /usr/local/sbin/systemx-stop ]; then
        /usr/local/sbin/systemx-stop
    elif [ -d "$CONFIG_DIR" ]; then
        cd "$CONFIG_DIR" && docker compose down 2>/dev/null || true
    fi
    
    print_info "Restoring configuration..."
    if [ -d "$backup_dir/$backup_name/config" ]; then
        cp -a "$backup_dir/$backup_name/config/"* "$CONFIG_DIR/"
        print_success "Configuration restored"
    fi
    
    print_info "Restoring logs..."
    if [ -d "$backup_dir/$backup_name/logs" ]; then
        mkdir -p /var/log/rysen
        cp -a "$backup_dir/$backup_name/logs/"* /var/log/rysen/
        print_success "Logs restored"
    fi
    
    # Create selfcare log files with correct permissions
    print_info "Setting up selfcare log files..."
    mkdir -p /var/log/rysen
    touch /var/log/rysen/security-audit.log
    touch /var/log/rysen/login-attempts.log
    chown www-data:www-data /var/log/rysen/security-audit.log /var/log/rysen/login-attempts.log
    chmod 644 /var/log/rysen/security-audit.log /var/log/rysen/login-attempts.log
    print_success "Selfcare log files created"
    
    print_info "Starting System-X services..."
    if [ -x /usr/local/sbin/systemx-start ]; then
        /usr/local/sbin/systemx-start
    elif [ -d "$CONFIG_DIR" ]; then
        cd "$CONFIG_DIR" && docker compose up -d 2>/dev/null || true
    fi
    
    # Clean up extracted backup directory (with safety check)
    if [ -n "$backup_dir" ] && [ -n "$backup_name" ]; then
        rm -rf "${backup_dir:?}/${backup_name:?}"
    fi
    
    print_success "Restore completed"
    press_enter
}

view_logs() {
    print_header "System Logs"
    
    if [ ! -d "/var/log/rysen" ]; then
        print_error "Log directory not found"
        press_enter
        return
    fi
    
    echo "1) View all logs"
    echo "2) View RYSEN logs"
    echo "3) View Docker logs"
    echo "4) View recent errors"
    echo "5) Back"
    echo ""
    read -p "Select option [1-5]: " choice
    
    case $choice in
        1)
            tail -n 100 /var/log/rysen/*.log 2>/dev/null || print_info "No logs found"
            ;;
        2)
            tail -n 100 /var/log/rysen/rysen*.log 2>/dev/null || print_info "No logs found"
            ;;
        3)
            if command -v docker &> /dev/null; then
                docker logs systemx 2>/dev/null || print_info "Container not running"
            else
                print_error "Docker not installed"
            fi
            ;;
        4)
            grep -i "error" /var/log/rysen/*.log 2>/dev/null | tail -n 50 || print_info "No errors found"
            ;;
        5)
            return
            ;;
        *)
            print_error "Invalid option"
            ;;
    esac
    
    press_enter
}

docker_status() {
    print_header "Docker Status"
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        press_enter
        return
    fi
    
    print_info "Docker version:"
    docker --version
    echo ""
    
    print_info "Docker Compose version:"
    docker compose version 2>/dev/null || echo "Not installed"
    echo ""
    
    print_info "Running containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "None"
    echo ""
    
    print_info "Docker disk usage:"
    docker system df 2>/dev/null || echo "Cannot retrieve"
    
    press_enter
}

network_diagnostics() {
    print_header "Network Diagnostics"
    
    print_info "Testing connectivity..."
    echo ""
    
    # Test DNS
    echo -n "DNS Resolution: "
    if nslookup github.com > /dev/null 2>&1; then
        print_success "OK"
    else
        print_error "Failed"
    fi
    
    # Test GitHub
    echo -n "GitHub: "
    if curl -s --connect-timeout 5 https://github.com > /dev/null 2>&1; then
        print_success "OK"
    else
        print_error "Failed"
    fi
    
    # Test GitHub API
    echo -n "GitHub API: "
    if curl -s --connect-timeout 5 ${GITHUB_API} > /dev/null 2>&1; then
        print_success "OK"
    else
        print_error "Failed"
    fi
    
    # Test Docker Hub
    echo -n "Docker Hub: "
    if curl -s --connect-timeout 5 https://hub.docker.com > /dev/null 2>&1; then
        print_success "OK"
    else
        print_error "Failed"
    fi
    
    echo ""
    print_info "Network interfaces:"
    ip addr show | grep "inet " | awk '{print $2}'
    
    press_enter
}

disk_usage() {
    print_header "Disk Usage Report"
    
    print_info "Overall disk usage:"
    df -h / /opt /var 2>/dev/null || df -h /
    echo ""
    
    if [ -d "$CONFIG_DIR" ]; then
        print_info "System-X configuration size:"
        du -sh "$CONFIG_DIR" 2>/dev/null || echo "Cannot calculate"
        echo ""
    fi
    
    if [ -d "/var/log/rysen" ]; then
        print_info "System-X logs size:"
        du -sh /var/log/rysen 2>/dev/null || echo "Cannot calculate"
        echo ""
    fi
    
    if command -v docker &> /dev/null; then
        print_info "Docker disk usage:"
        docker system df 2>/dev/null || echo "Cannot retrieve"
    fi
    
    press_enter
}

register_installation() {
    print_header "Register Installation"
    
    if [ ! -x /usr/local/sbin/systemx-register ]; then
        print_error "Registration command not found"
        print_error "Please install System-X first"
        press_enter
        return
    fi
    
    /usr/local/sbin/systemx-register
    
    press_enter
}

migrate_from_v13() {
    print_header "Migrate System-X v1.3.x to v1.4.0"
    
    # Check if migration needed
    if [ -f "/etc/rysen/.installer_version" ]; then
        local current_version=$(cat /etc/rysen/.installer_version)
        print_warning "System already reports version: $current_version"
        echo ""
        read -p "Force migration anyway? (y/n): " force
        if [ "$force" != "y" ] && [ "$force" != "Y" ]; then
            press_enter
            return
        fi
    fi
    
    # Check if System-X installed
    if [ ! -d "$CONFIG_DIR" ] || [ ! -f "$CONFIG_DIR/rysen.cfg" ]; then
        print_error "System-X does not appear to be installed"
        print_info "Use option [1] Install System-X for fresh installation"
        press_enter
        return
    fi
    
    # Display migration overview
    print_info "This migration will:"
    echo "  - Create automatic backup of current configuration"
    echo "  - Update all control scripts to v1.4.0"
    echo "  - Install Docker Compose v2 (if needed)"
    echo "  - Update docker-compose.yml"
    echo "  - Add version tracking"
    echo "  - Restart services"
    echo ""
    print_warning "Total time: ~5-10 minutes"
    print_warning "Services will be briefly offline during restart"
    echo ""
    
    read -p "Continue with migration? (y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_info "Migration cancelled"
        press_enter
        return
    fi
    
    # Ensure token is validated
    if [ -z "$GITHUB_TOKEN" ] || [ "$TOKEN_VALIDATED" != true ]; then
        print_error "GitHub token not validated"
        print_info "Token is required for repository access"
        echo ""
        if ! prompt_token; then
            print_error "Migration cancelled - token required"
            press_enter
            return
        fi
    fi
    
    # Create pre-migration backup
    # Note: This creates a simpler backup than backup_installation() since we need
    # the backup directory structure for potential manual rollback during migration
    print_info "Creating pre-migration backup..."
    local backup_dir="/opt/backups"
    local backup_name="pre-v14-migration-$(date +%Y%m%d-%H%M%S)"
    local backup_path="$backup_dir/$backup_name"
    
    mkdir -p "$backup_dir"
    mkdir -p "$backup_path"
    
    # Backup configuration
    if [ -d "$CONFIG_DIR" ]; then
        cp -a "$CONFIG_DIR" "$backup_path/config" 2>/dev/null || true
    fi
    
    # Backup control scripts
    mkdir -p "$backup_path/sbin"
    for script in menu menu-spanish systemx-*; do
        if [ -f "/usr/local/sbin/$script" ]; then
            cp "/usr/local/sbin/$script" "$backup_path/sbin/" 2>/dev/null || true
        fi
    done
    
    # Backup docker-compose.yml
    if [ -f "$INSTALL_DIR/docker-compose.yml" ]; then
        cp "$INSTALL_DIR/docker-compose.yml" "$backup_path/docker-compose.yml.backup" 2>/dev/null || true
    fi
    
    print_success "Backup created: $backup_path"
    echo ""
    
    # One-time v1.3.9r3 → v1.4.0 config migration
    print_info "Checking for v1.3.9r3 configuration files..."
    
    if [ -f "/etc/rysen/proxy.cfg" ] && [ ! -f "/etc/rysen/proxy-selfcare.cfg" ]; then
        print_info "Migrating v1.3.9r3 proxy.cfg → proxy-selfcare.cfg..."
        cp /etc/rysen/proxy.cfg /etc/rysen/proxy-selfcare.cfg
        
        if ! grep -q "^\[SELF SERVICE\]" /etc/rysen/proxy-selfcare.cfg; then
            cat >> /etc/rysen/proxy-selfcare.cfg << 'EOF'

[SELF SERVICE]
USE_SELFSERVICE = True
SERVER = 172.16.238.11
USERNAME = selfcare
# CHANGE THIS BEFORE PRODUCTION DEPLOYMENT!
PASSWORD = freestar3
DB_NAME = selfcare
PORT = 3306
EOF
        fi
        
        mv /etc/rysen/proxy.cfg /etc/rysen/proxy.cfg.v13-backup
        print_success "Migrated proxy.cfg (backup: proxy.cfg.v13-backup)"
    fi
    
    if [ -f "/etc/rysen/rymon.cfg" ] && [ ! -f "/etc/rysen/fdmr-mon.cfg" ]; then
        print_info "Migrating ancient rymon.cfg → fdmr-mon.cfg..."
        cp /etc/rysen/rymon.cfg /etc/rysen/fdmr-mon.cfg
        mv /etc/rysen/rymon.cfg /etc/rysen/rymon.cfg.ancient-backup
        print_success "Migrated rymon.cfg (backup: rymon.cfg.ancient-backup)"
    fi
    echo ""
    
    # Clone repository
    print_info "Cloning System-X repository..."
    # Use /opt/tmp for migration to keep working files separate from system /tmp
    # This allows easier troubleshooting and prevents cleanup during system maintenance
    local temp_dir="/opt/tmp/systemx-migrate-$$"
    mkdir -p "$temp_dir"
    
    if ! git clone "https://${GITHUB_TOKEN}@github.com/${REPO_OWNER}/${REPO_NAME}.git" "$temp_dir" 2>&1 | grep -v "Cloning into"; then
        print_error "Failed to clone repository"
        print_info "Backup available at: $backup_path"
        rm -rf "$temp_dir"
        press_enter
        return
    fi
    
    print_success "Repository cloned successfully"
    echo ""
    
    # Install Docker Compose v2
    print_info "Checking Docker Compose v2..."
    if docker compose version >/dev/null 2>&1; then
        local compose_version=$(docker compose version --short 2>/dev/null || docker compose version | head -1 | awk '{print $NF}')
        print_success "Docker Compose v2 already installed (version: $compose_version)"
    else
        print_info "Installing docker-compose-plugin..."
        apt-get update -qq
        apt-get install -y docker-compose-plugin
        
        if docker compose version >/dev/null 2>&1; then
            print_success "Docker Compose v2 installed"
        else
            print_error "Failed to install Docker Compose v2"
            print_info "Backup available at: $backup_path"
            rm -rf "$temp_dir"
            press_enter
            return
        fi
    fi
    
    # Create backward compatibility wrapper
    if [ ! -f /usr/local/bin/docker-compose ] || ! grep -q "exec docker compose" /usr/local/bin/docker-compose 2>/dev/null; then
        print_info "Creating backward compatibility wrapper..."
        cat > /usr/local/bin/docker-compose <<'EOF'
#!/bin/sh
exec docker compose "$@"
EOF
        chmod 755 /usr/local/bin/docker-compose
        print_success "Wrapper script created"
    fi
    echo ""
    
    # Stop services
    print_info "Stopping System-X services..."
    if [ -x /usr/local/sbin/systemx-stop ]; then
        /usr/local/sbin/systemx-stop 2>/dev/null || true
    else
        cd "$INSTALL_DIR" 2>/dev/null && docker compose down 2>/dev/null || true
    fi
    print_success "Services stopped"
    echo ""
    
    # Update control scripts
    print_info "Updating control scripts..."
    if [ -d "$temp_dir/configs/sbin" ]; then
        # Install shared library
        cp "$temp_dir/configs/sbin/systemx-common" /usr/local/sbin/
        chmod 755 /usr/local/sbin/systemx-common
        
        # Install language system
        mkdir -p /usr/local/sbin/systemx-lang
        cp "$temp_dir/configs/sbin/systemx-lang-loader" /usr/local/sbin/
        chmod 755 /usr/local/sbin/systemx-lang-loader
        cp "$temp_dir/configs/sbin/systemx-lang/"*.lang /usr/local/sbin/systemx-lang/ 2>/dev/null || true
        cp "$temp_dir/configs/sbin/systemx-lang/README.md" /usr/local/sbin/systemx-lang/ 2>/dev/null || true
        chmod 644 /usr/local/sbin/systemx-lang/*.lang 2>/dev/null || true
        chmod 644 /usr/local/sbin/systemx-lang/README.md 2>/dev/null || true
        
        # Install new menu system
        cp "$temp_dir/configs/sbin/systemx-menu" /usr/local/sbin/menu
        cp "$temp_dir/configs/sbin/systemx-service" /usr/local/sbin/
        cp "$temp_dir/configs/sbin/systemx-config" /usr/local/sbin/
        chmod 755 /usr/local/sbin/menu
        chmod 755 /usr/local/sbin/systemx-service
        chmod 755 /usr/local/sbin/systemx-config
        
        # Install/update all systemx-* scripts
        for script in "$temp_dir/configs/sbin/systemx-"*; do
            [ -f "$script" ] || continue
            script_name=$(basename "$script")
            # Skip already copied scripts
            [[ "$script_name" == "systemx-menu" ]] && continue
            [[ "$script_name" == "systemx-service" ]] && continue
            [[ "$script_name" == "systemx-config" ]] && continue
            [[ "$script_name" == "systemx-common" ]] && continue
            [[ "$script_name" == "systemx-lang-loader" ]] && continue
            cp "$script" "/usr/local/sbin/$script_name"
            chmod 755 "/usr/local/sbin/$script_name"
        done
        
        # Create compatibility symlinks
        ln -sf systemx-service /usr/local/sbin/systemx-start
        ln -sf systemx-service /usr/local/sbin/systemx-stop
        ln -sf systemx-service /usr/local/sbin/systemx-restart
        ln -sf systemx-service /usr/local/sbin/systemx-flush
        ln -sf systemx-service /usr/local/sbin/systemx-soft-flush
        
        # Spanish menu wrapper
        cat > /usr/local/sbin/menu-spanish << 'EOFSPANISH'
#!/bin/bash
export SYSTEMX_LANG=es
exec /usr/local/sbin/menu "$@"
EOFSPANISH
        chmod 755 /usr/local/sbin/menu-spanish
        
        chown root:root /usr/local/sbin/menu
        chown root:root /usr/local/sbin/menu-spanish
        chown root:root /usr/local/sbin/systemx-*
        
        print_success "Control scripts updated"
    else
        print_error "Control scripts not found in repository"
        print_info "Backup available at: $backup_path"
        rm -rf "$temp_dir"
        press_enter
        return
    fi
    echo ""
    
    # Install Token Status Broadcaster
    print_header "Token Status Broadcaster Setup"
    
    if [ -f "$temp_dir/configs/sbin/systemx-token-broadcaster" ]; then
        print_info "Installing token status broadcaster..."
        cp "$temp_dir/configs/sbin/systemx-token-broadcaster" /usr/local/sbin/systemx-token-broadcaster
        chmod 755 /usr/local/sbin/systemx-token-broadcaster
        chown root:root /usr/local/sbin/systemx-token-broadcaster
        print_success "Broadcaster installed"
        
        # Add cron job
        if ! crontab -l 2>/dev/null | grep -q "systemx-token-broadcaster"; then
            (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/sbin/systemx-token-broadcaster >/dev/null 2>&1") | crontab -
            print_success "Cron job configured"
        fi
        
        # Report initial status
        /usr/local/sbin/systemx-token-broadcaster &
        print_success "Status reported"
    else
        print_warning "Broadcaster not found in repository"
    fi
    
    # Install Automatic Update Checker
    if [ -f "$temp_dir/configs/sbin/systemx-check-updates-cron" ]; then
        print_info "Installing automatic update checker..."
        cp "$temp_dir/configs/sbin/systemx-check-updates-cron" /usr/local/sbin/systemx-check-updates-cron
        chmod 755 /usr/local/sbin/systemx-check-updates-cron
        chown root:root /usr/local/sbin/systemx-check-updates-cron
        print_success "Update checker installed"
        
        # Add cron job
        if ! crontab -l 2>/dev/null | grep -q "systemx-check-updates-cron"; then
            (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/sbin/systemx-check-updates-cron >/dev/null 2>&1") | crontab -
            print_success "Update check cron job configured (daily at 2 AM)"
        fi
        
        # Run initial update check
        /usr/local/sbin/systemx-check-updates-cron &
        print_success "Initial update check completed"
    else
        print_warning "Update checker not found in repository"
    fi
    
    echo ""
    
    # Update docker-compose.yml
    print_info "Updating docker-compose.yml..."
    if [ -f "$temp_dir/configs/docker-configs/docker-compose-user.yml" ]; then
        # Backup existing docker-compose.yml with timestamp
        if [ -f "$INSTALL_DIR/docker-compose.yml" ]; then
            cp "$INSTALL_DIR/docker-compose.yml" "$INSTALL_DIR/docker-compose.yml.backup.$(date +%Y%m%d-%H%M%S)"
        fi
        
        # Copy new docker-compose.yml
        cp "$temp_dir/configs/docker-configs/docker-compose-user.yml" "$INSTALL_DIR/docker-compose.yml"
        print_success "docker-compose.yml updated"
    else
        print_error "docker-compose.yml not found in repository"
        print_info "Backup available at: $backup_path"
        rm -rf "$temp_dir"
        press_enter
        return
    fi
    echo ""
    
    # Create version tracking
    print_info "Creating version tracking..."
    local new_version=$(cd "$temp_dir" && git rev-parse HEAD 2>/dev/null | cut -c1-7)
    if [ -z "$new_version" ]; then
        new_version="1.4.0"
    fi
    
    echo "$new_version" > /etc/rysen/.installer_version
    echo "$INSTALL_DIR" > /etc/rysen/.installer_path
    chmod 644 /etc/rysen/.installer_version
    chmod 644 /etc/rysen/.installer_path
    chown root:root /etc/rysen/.installer_version
    chown root:root /etc/rysen/.installer_path
    print_success "Version tracking initialized: $new_version"
    echo ""
    
    # Restart services
    print_info "Starting System-X services..."
    cd "$INSTALL_DIR"
    
    print_info "Pulling latest images..."
    docker compose pull
    
    print_info "Starting containers..."
    if docker compose up -d --force-recreate; then
        print_success "Services started"
        sleep 5
        
        print_info "Verifying containers..."
        docker compose ps
    else
        print_error "Failed to start services"
        print_info "Check logs with: docker compose -f $INSTALL_DIR/docker-compose.yml logs"
        print_info "Backup available at: $backup_path"
        rm -rf "$temp_dir"
        press_enter
        return
    fi
    echo ""
    
    # Cleanup
    print_info "Cleaning up temporary files..."
    rm -rf "$temp_dir"
    print_success "Cleanup complete"
    echo ""
    
    # Success message
    print_success "Migration completed successfully!"
    echo ""
    print_info "Migration Summary:"
    echo "  - Version: $new_version"
    echo "  - Backup: $backup_path"
    echo "  - Services: Running"
    echo ""
    print_info "New Features Available:"
    echo "  • systemx-upgrade        - Full system upgrade"
    echo "  • systemx-upgrade-dryrun - Preview changes"
    echo "  • systemx-check-updates  - Check for updates"
    echo "  • systemx-rollback       - Restore from backup"
    echo ""
    
    # Offer registration if not already registered
    if [ -x /usr/local/sbin/systemx-validate-token ]; then
        if ! /usr/local/sbin/systemx-validate-token >/dev/null 2>&1; then
            echo ""
            print_warning "Installation not registered"
            print_info "Registration enables authorized updates and upgrades"
            echo ""
            read -p "Register installation now? (y/n): " register_choice
            if [ "$register_choice" = "y" ] || [ "$register_choice" = "Y" ]; then
                echo ""
                register_installation
            else
                print_info "You can register later using option [7] Register Installation"
            fi
        fi
    fi
    
    press_enter
}

################################################################################
# System Information
################################################################################

show_system_info() {
    print_header "System Information"
    
    echo -e "${CYAN}Operating System:${NC}"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "  Distribution: $PRETTY_NAME"
        echo "  Version: $VERSION"
    fi
    echo ""
    
    echo -e "${CYAN}Hardware:${NC}"
    echo "  CPU: $(lscpu | grep "Model name" | cut -d: -f2 | xargs)"
    echo "  Cores: $(nproc)"
    echo "  RAM: $(free -h | grep Mem | awk '{print $2}')"
    echo ""
    
    echo -e "${CYAN}Network:${NC}"
    local_ip=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7; exit}')
    [ -z "$local_ip" ] && local_ip="Unknown"
    external_ip=$(curl -s --connect-timeout 5 https://ipecho.net/plain 2>/dev/null || echo "Unknown")
    echo "  Hostname: $(hostname)"
    echo "  Local IP: $local_ip"
    echo "  External IP: $external_ip"
    echo ""
    
    echo -e "${CYAN}System-X Status:${NC}"
    if [ -d "$CONFIG_DIR" ]; then
        echo "  Installation: Detected"
        if [ -f "$CONFIG_DIR/rysen.cfg" ]; then
            echo "  Configuration: Present"
        fi
        if [ -f /etc/rysen/.installer_version ]; then
            echo "  Version: $(cat /etc/rysen/.installer_version)"
        fi
        if [ -x /usr/local/sbin/systemx-validate-token ]; then
            if /usr/local/sbin/systemx-validate-token >/dev/null 2>&1; then
                echo "  Authorization: ✓ Authorized"
            else
                echo "  Authorization: ✗ Unauthorized"
            fi
        fi
    else
        echo "  Installation: Not detected"
    fi
    echo ""
    
    echo -e "${CYAN}Docker Status:${NC}"
    if command -v docker &> /dev/null; then
        echo "  Docker: Installed"
        echo "  Version: $(docker --version | cut -d' ' -f3 | tr -d ',')"
        if docker compose version >/dev/null 2>&1; then
            echo "  Compose: Installed"
        else
            echo "  Compose: Not installed"
        fi
        local running=$(docker ps -q 2>/dev/null | wc -l)
        echo "  Running Containers: $running"
    else
        echo "  Docker: Not installed"
    fi
    
    press_enter
}

################################################################################
# Help & Documentation
################################################################################

show_help() {
    print_header "Help & Documentation"
    
    cat <<EOF
System-X Deployment Script - Quick Reference
=============================================

MAIN MENU OPTIONS:

[1] Install System-X
    - Fresh installation of System-X
    - Requires GitHub Personal Access Token
    - Installs all components and dependencies
    - Creates initial configuration

[2] Upgrade System-X
    - Upgrades existing installation
    - Creates automatic backup before upgrade
    - Preserves configuration and data
    - Requires registered installation

[3] Uninstall System-X
    - Complete removal of System-X
    - Creates automatic backup before removal
    - Removes all components safely
    - Preserves backups for restoration

[4] Utilities
    - Backup/Restore operations
    - Log viewing and analysis
    - Docker status and management
    - Network diagnostics
    - Disk usage reporting
    - Installation registration
    - Migration from v1.3.x

[5] System Information
    - View system hardware details
    - Check installation status
    - Verify authorization status
    - Review Docker status

[6] Validate Token
    - Test GitHub token validity
    - Check repository access
    - Verify permissions

[7] Help & Documentation
    - This help screen
    - Quick reference guide

TOKEN REQUIREMENTS:

System-X requires a GitHub Personal Access Token (PAT) for installation
and updates. Contact your System-X administrator to obtain a token.

Token Format:
  - Classic: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  - Fine-grained: github_pat_xxxxxxxxxx...

Required Permissions:
  - repo: Full control of private repositories
  - Specifically for: The System-X installation repository

SYSTEM REQUIREMENTS:

Supported Operating Systems:
  - Debian 11, 12, 13
  - Ubuntu 22.04 LTS, 24.04 LTS

Minimum Hardware:
  - 2 CPU cores
  - 2 GB RAM
  - 20 GB disk space
  - Active internet connection

COMMON TASKS:

Install System-X:
  1. Run this script as root
  2. Enter GitHub token when prompted
  3. Select option [1] Install
  4. Follow on-screen instructions

Upgrade System-X:
  1. Select option [2] Upgrade
  2. Automatic backup will be created
  3. Follow on-screen instructions

Backup Configuration:
  1. Select option [4] Utilities
  2. Select option [1] Backup
  3. Backup saved to /opt/backups/

SUPPORT:

For assistance, contact your System-X administrator:
  Email: shane@freestar.network
  Discord: Contact via FreeSTAR Network Discord server

Documentation:
  - README.md in deployment directory
  - DEPLOYMENT_GUIDE.md for administrators

EOF
    
    press_enter
}

validate_token_menu() {
    print_header "Validate GitHub Token"
    
    if [ -z "$GITHUB_TOKEN" ] || [ "$TOKEN_VALIDATED" != true ]; then
        print_info "No token currently set"
        echo ""
        read -p "Enter token to validate? (y/n): " choice
        if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
            prompt_token
        fi
    else
        print_success "Token is currently validated"
        print_info "Checking current status..."
        validate_token_api "$GITHUB_TOKEN"
    fi
    
    press_enter
}

################################################################################
# Main Menu
################################################################################

show_banner() {
    clear
    echo -e "${CYAN}"
    cat <<'EOF'
╔═══════════════════════════════════════════════════════════════════════╗
║                               FreeSTAR                                ║
║   ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗    ██╗  ██╗   ║
║   ██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║    ╚██╗██╔╝   ║
║   ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║     ╚███╔╝    ║
║   ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║     ██╔██╗    ║
║   ███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║    ██╔╝ ██╗   ║
║   ╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝    ╚═╝  ╚═╝   ║
║                                                                       ║
║                     DEPLOYMENT & MANAGEMENT SYSTEM                    ║
║                             Version 1.4.0                             ║
║                                 RYSEN                                 ║
╚═══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

main_menu() {
    while true; do
        show_banner
        
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo "  [1] Install System-X       - Fresh installation"
        echo "  [2] Upgrade System-X       - Upgrade existing installation"
        echo "  [3] Uninstall System-X     - Complete removal"
        echo "  [4] Utilities              - Maintenance tools"
        echo "  [5] System Information     - View system status"
        echo "  [6] Validate Token         - Test GitHub token"
        echo "  [7] Help & Documentation   - View help"
        echo "  [Q] Quit                   - Exit deployment script"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
        echo ""
        
        # Show token status
        if [ "$TOKEN_VALIDATED" = true ]; then
            echo -e "Token Status: ${GREEN}✓ Validated${NC}"
        else
            echo -e "Token Status: ${YELLOW}⚠ Not validated${NC}"
        fi
        echo ""
        
        read -p "Select option [1-7, Q]: " choice
        
        case $choice in
            1)
                install_systemx
                ;;
            2)
                upgrade_systemx
                ;;
            3)
                uninstall_systemx
                ;;
            4)
                utilities_menu
                ;;
            5)
                show_system_info
                ;;
            6)
                validate_token_menu
                ;;
            7)
                show_help
                ;;
            q|Q)
                print_info "Exiting deployment script"
                exit 0
                ;;
            *)
                print_error "Invalid option"
                press_enter
                ;;
        esac
    done
}

################################################################################
# Main Entry Point
################################################################################

main() {
    # Root check
    check_root
    
    # OS check
    check_os
    
    # Network check (non-fatal)
    check_network || print_warning "Network connectivity issues detected"
    
    # Prompt for token
    if ! prompt_token; then
        print_warning "Continuing without validated token"
        print_warning "Some operations may not be available"
        sleep 2
    fi
    
    # Start main menu
    main_menu
}

# Run main function
main
