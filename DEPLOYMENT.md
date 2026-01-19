# FreeSTAR SystemX Deployment Tool

**Deployment for FreeSTAR SystemX installations**

This repository contains `systemx-deploy.sh`, a comprehensive deployment and management tool for authorised System-X installations.  It provides automated installation, upgrades, backups, and system utilities.

## Overview

The SystemX deployment script is designed for authorized system operators to: 
- **Install** new System-X instances
- **Upgrade** existing installations
- **Manage** configurations and backups
- **Diagnose** system health and connectivity
- **Monitor** Docker services and resources

## System Requirements

### Supported Operating Systems
- **Debian:** 11, 12, 13
- **Ubuntu:** 22.04 LTS, 24.04 LTS

### Minimum Hardware
- **CPU:** 2 cores
- **RAM:** 2 GB (4+ GB recommended)
- **Storage:** 20 GB available disk space
- **Network:** Stable internet connection with GitHub access

## Pre-Installation Setup

**IMPORTANT:** Complete these steps before running the deployment script to ensure proper security and administrative access.

### 1. System Preparation

#### Update System Packages
```bash
sudo apt update && sudo apt upgrade -y
```

#### Install Required Dependencies
```bash
sudo apt install -y git curl
```

**Note:** `openssh-server` is typically pre-installed on Debian and Ubuntu server systems.  If SSH is not available, install it with:
```bash
sudo apt install -y openssh-server
```

### 2. SSH Security Configuration

#### Enable SSH Service
```bash
sudo systemctl enable ssh
sudo systemctl start ssh
```

#### Configure FreeSTAR Admin Access

To allow FreeSTAR administrators secure access to your system for support and maintenance:

```bash
# Create SSH directory if it doesn't exist
mkdir -p ~/. ssh
chmod 700 ~/.ssh

# Download FreeSTAR administrative SSH keys
curl https://api.freestar.network/v1/keychain/root.keys > ~/.ssh/authorized_keys

# Set proper permissions
chmod 600 ~/.ssh/authorized_keys
```

#### Disable Password Authentication (Recommended)

For enhanced security, disable password-based SSH authentication:

```bash
sudo nano /etc/ssh/sshd_config
```

Make the following changes:
```
# Disable password authentication
PasswordAuthentication no

# Disable root password login (key-based auth still allowed)
PermitRootLogin prohibit-password

# Enable public key authentication
PubkeyAuthentication yes

# Disable empty passwords
PermitEmptyPasswords no

# Optional: Change default SSH port (e.g., to 2222)
# Port 2222
```

Save the file and restart SSH:
```bash
sudo systemctl restart ssh
```

**⚠️ WARNING:** Before disabling password authentication, ensure you can successfully connect using SSH keys. Test in a separate session to avoid being locked out.

#### Test Administrative Access

From another terminal or system, verify SSH key authentication works:
```bash
ssh -i /path/to/admin/key user@your-server-ip
```

### 3. Firewall Configuration

**⚠️ IMPORTANT - VPS/Cloud Providers:** If using Vultr, DigitalOcean, AWS, or other VPS/cloud providers, **disable UFW** as it conflicts with their firewall management systems: 

```bash
sudo ufw disable
```

Manage firewall rules through your provider's control panel instead (Vultr Firewall, DigitalOcean Cloud Firewall, AWS Security Groups, etc.).

---

If using a bare-metal server or local installation, you may optionally configure UFW: 

```bash
sudo apt install -y ufw
sudo ufw allow 22/tcp          # SSH (adjust if using custom port)
sudo ufw allow 80/tcp           # HTTP
sudo ufw allow 443/tcp          # HTTPS
sudo ufw allow 62031/udp        # DMR ports (adjust as needed)
sudo ufw enable
```

### 4. Pre-Installation Verification Checklist

Before proceeding with System-X deployment, verify: 

- [ ] System packages are updated
- [ ] Git and curl are installed
- [ ] SSH server is running (`sudo systemctl status ssh`)
- [ ] FreeSTAR admin keys are installed in `~/.ssh/authorized_keys`
- [ ] SSH configuration is secured (password auth disabled)
- [ ] Docker and Docker Compose v2 are installed and running
- [ ] Firewall is configured appropriately (UFW disabled for VPS)
- [ ] Internet connectivity to GitHub (`curl -I https://github.com`)
- [ ] You have your GitHub Personal Access Token ready

## Authentication

System-X installations require a **GitHub Personal Access Token (PAT)** for authorised use. Contact your FreeSTAR administrator to obtain a token with appropriate permissions.

### Token Formats

The script accepts two token formats:
- **Classic:** `ghp_` followed by 36 characters
- **Fine-grained:** `github_pat_` followed by additional characters

## Quick Start

### Download and Run the Deployment Script

```bash
cd /opt
git clone https://github.com/ShaYmez/freestar-systemx-deploy.git
cd freestar-systemx-deploy
sudo ./systemx-deploy.sh
```

### Interactive Menu Options

| Option | Function |
|--------|----------|
| **[1]** | Install System-X (fresh installation) |
| **[2]** | Upgrade System-X (existing installation) |
| **[3]** | Uninstall System-X |
| **[4]** | Utilities (backup, restore, diagnostics, migration) |
| **[5]** | System Information |
| **[6]** | Validate Token |
| **[7]** | Help & Documentation |
| **[0]** | Exit |

## Installation Process

The installer performs the following steps:

1. **System Checks** - Verifies OS compatibility, network connectivity, and root access
2. **Token Validation** - Validates GitHub PAT format and API access
3. **Repository Cloning** - Downloads the official installer from GitHub
4. **Installer Execution** - Runs System-X installer, configures Docker services, initializes configuration
5. **Cleanup** - Removes temporary files and secures token from memory

### What Gets Installed

- Docker containers and services
- RYSEN DMRMaster+
- System-X monitoring dashboard
- RYSEN control scripts
- Configuration templates
- Database initialization
- Web server configuration

## Utilities Menu

Access via **[4] Utilities** in the main menu:

| Utility | Description |
|---------|-------------|
| **Backup Configuration** | Creates timestamped backup at `/opt/backups/systemx-backup-YYYYMMDD-HHMMSS.tar.gz` |
| **Restore from Backup** | Lists and restores previous backups |
| **View System Logs** | Display and filter System-X logs |
| **Docker Status** | Show container health, CPU/memory usage |
| **Network Diagnostics** | Test GitHub connectivity, DNS resolution |
| **Disk Usage Report** | Display filesystem and Docker disk usage |
| **Registration** | Register installation with FreeSTAR Network |
| **Migrate from v1.3.x** | Automated migration preserving data and configurations |

## Upgrade Management

### Check for Updates
```bash
./systemx-deploy.sh
# Select [2] Upgrade System-X
```

The upgrade process:
- Creates automatic backup
- Downloads latest System-X installer
- Updates all components while preserving configuration and data
- Performs health check after upgrade

### Rollback
Automatic backups are created before each upgrade.  Restore previous versions from `/opt/backups/` if needed.

## Migrating from v1.3.x

If you have an existing System-X v1.3.x installation:

1. Run the deployment script:  `sudo ./systemx-deploy.sh`
2. Navigate to **[4] Utilities** → **[8] Migrate from v1.3.x**
3. Follow the automated migration process

### What Gets Updated
- All control scripts (menu, systemx-upgrade, systemx-check-updates)
- Docker Compose upgraded to v2
- Version tracking system initialized

### What Remains Unchanged
- All configuration files (rysen.cfg, rules.py, proxy.cfg)
- All passwords, credentials, data, and logs
- Docker volumes and networks
- Custom artwork, configurations, and marquee

An automatic backup is created at `/opt/backups/pre-v14-migration-[timestamp]/` before migration starts.

## Uninstallation

```bash
./systemx-deploy. sh
# Select [3] Uninstall System-X
```

The uninstaller:
- Creates automatic backup before removal
- Stops and removes Docker containers
- Optionally preserves configuration directories
- Disables System-X services
- Cleans up temporary files

Backups are retained in `/opt/backups/` and can be restored at any time.

## Troubleshooting

### Token Validation Fails

**"Cannot access repository"**
- Verify token has been provided and has not expired
- Confirm token has 'repo' scope permission
- Contact administrator for new token

**"Invalid token format"**
- Classic tokens start with `ghp_`
- Fine-grained tokens start with `github_pat_`
- No spaces or special characters allowed

### Network Issues

**"Cannot reach github.com" or "Cannot reach GitHub API"**
- Check internet connection and firewall settings
- Test with:  `curl https://github.com`
- GitHub API may be temporarily unavailable - retry after a few minutes

### Docker Issues

**"Docker not found" or "Docker Compose not found"**
- Install Docker:  `sudo apt install docker.io`
- Install Docker Compose v2: `sudo apt install docker-compose-v2`
- Verify:  `docker --version && docker compose version`

### SSH Access Issues

**Cannot connect via SSH keys:**
- Verify keys downloaded correctly:  `cat ~/.ssh/authorized_keys`
- Check file permissions: `ls -la ~/.ssh/`
- Ensure SSH service is running: `sudo systemctl status ssh`
- Check firewall rules allow SSH port

**Locked out after disabling password auth:**
- Access via console (physical or VPS console)
- Re-enable password auth temporarily
- Fix SSH key configuration
- Test key access before disabling passwords again

### Installation Already Exists

The script detects existing installations and offers to:
- Create backup before reinstalling
- Use upgrade path instead of fresh install
- Preserve all existing data

## Security Considerations

### Token Security
- Never commit tokens to version control
- Store tokens in a secure vault
- Use token expiration in GitHub settings
- Remove from shell history:  `unset GITHUB_TOKEN`
- **A compromised token will result in an instant ban! **

### System Security
- Change default System-X passwords immediately after install
- Disable password-based SSH authentication
- Use SSH key authentication only
- Allow FreeSTAR admin access for support
- Regularly review `~/.ssh/authorized_keys`
- Keep OS and Docker updated
- Monitor access logs regularly

### Backups
- Regular automated backups recommended
- Store backups in secure location
- Test restore process periodically
- Retain at least 3-5 recent backups

## File Locations

| Path | Purpose |
|------|---------|
| `/opt/RYSEN` | Application installation directory |
| `/opt/freestar-systemx-deploy` | Deployment script location |
| `/opt/backups` | Backup archives |
| `/etc/rysen` | Configuration files |
| `/var/log/rysen` | System logs |
| `/var/www/html/dashboard` | Web dashboard files |

## Getting Help

### Run Diagnostics
```bash
./systemx-deploy.sh
# Select [4] Utilities → [5] Network Diagnostics
# Or [5] System Information
```

### Contact Support
For installation issues or questions:
- Contact your FreeSTAR SystemX administrator
- Refer to deployment logs for error details
- Provide system information when reporting issues

## Version Information

- **Current Version:** 1.4.0
- **Release Date:** January 15, 2026
- **Supported Installer:** System-X-Installer v1.4.0+

## License

This deployment script is part of the FreeSTAR SystemX project. 
Licensed under MIT License - See LICENSE file for details. 

---

**For authorized system operators only.**

**Copyright © 2021-2026 Shane Daley, M0VUB**
