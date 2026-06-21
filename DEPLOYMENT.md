# System-X Deployment Guide

**Version 1.4.1+**

Complete installation and operations guide for authorized FreeSTAR System-X operators using [freestar-systemx-deploy](https://github.com/ShaYmez/freestar-systemx-deploy).

---

## Table of Contents

- [Quick Start](#quick-start)
- [Pre-Installation Setup](#pre-installation-setup)
- [Authentication](#authentication)
- [Installation Process](#installation-process)
- [Post-Installation](#post-installation)
- [Network & API Configuration](#network--api-configuration)
- [Upgrade Management](#upgrade-management)
- [Migrating from v1.3.x](#migrating-from-v13x)
- [Utilities Menu](#utilities-menu)
- [Uninstallation](#uninstallation)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [File Locations](#file-locations)
- [Documentation Index](#documentation-index)

---

## Quick Start

```bash
cd /opt
git clone https://github.com/ShaYmez/freestar-systemx-deploy.git
cd freestar-systemx-deploy
sudo ./systemx-deploy.sh
```

Select **[1] Install System-X** and follow the prompts. You need a GitHub Personal Access Token from the FreeSTAR team.

Complete [Pre-Installation Setup](#pre-installation-setup) before your first install.

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

See [README.md](README.md) for authorization criteria and hardware requirements.

---

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

**Note:** `openssh-server` is typically pre-installed on Debian and Ubuntu server systems. If SSH is not available:

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

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
curl https://api.freestar.network/v1/keychain/root.keys > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

#### Disable Password Authentication (Recommended)

```bash
sudo nano /etc/ssh/sshd_config
```

Recommended settings:

```
PasswordAuthentication no
PermitRootLogin prohibit-password
PubkeyAuthentication yes
PermitEmptyPasswords no
```

Restart SSH:

```bash
sudo systemctl restart ssh
```

**WARNING:** Test SSH key login in a separate session before disabling password authentication.

### 3. Firewall Configuration

**VPS/cloud providers (Vultr, DigitalOcean, AWS, etc.):** disable UFW — use the provider firewall instead:

```bash
sudo ufw disable
```

**Bare-metal or self-managed servers** may optionally use UFW:

```bash
sudo apt install -y ufw
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 62031/udp
sudo ufw enable
```

### 4. Pre-Installation Checklist

- [ ] Debian 11/12/13 or Ubuntu 22.04/24.04 LTS
- [ ] VPS or dedicated server (not home hosting)
- [ ] Root SSH access; key-based auth configured
- [ ] Docker and Docker Compose v2 installed
- [ ] GitHub PAT from FreeSTAR administrator
- [ ] FreeSTAR admin SSH access provisioned
- [ ] Internet connectivity to GitHub (`curl -I https://github.com`)

---

## Authentication

System-X installations require a **GitHub Personal Access Token (PAT)** for authorised use. Contact your FreeSTAR administrator to obtain a token.

### Token Formats

- **Classic:** `ghp_` followed by 36 characters
- **Fine-grained:** `github_pat_` followed by additional characters

The script validates format, GitHub API access, and repository permissions automatically.

---

## Installation Process

1. **System Checks** — OS compatibility, network connectivity, root access
2. **Token Validation** — GitHub PAT format and API access
3. **Repository Cloning** — downloads System-X-Installer from GitHub
4. **Installer Execution** — runs `systemx-docker-install.sh`, configures Docker services
5. **Cleanup** — removes temporary files and clears token from memory

### What Gets Installed

- Docker containers and services
- RYSEN DMRMaster+
- System-X monitoring dashboard
- Control scripts (`menu`, `systemx-upgrade`, etc.)
- Configuration templates and database initialization
- Web server configuration

---

## Post-Installation

### Verify services

```bash
menu                    # Interactive control panel
cd /etc/rysen && docker compose ps
```

### Token status reporting (automatic)

System-X reports verification status to the central API every 5 minutes. No manual setup required on a default FreeSTAR install.

```bash
sudo /usr/local/sbin/systemx-token-broadcaster   # Manual test
crontab -l | grep systemx-token-broadcaster      # Verify cron
```

### Default passwords

Change default credentials immediately after install (documented in installer output).

---

## Network & API Configuration

System-X stores **network identity and API URLs** in one file:

```
/etc/rysen/systemx-network.ini
```

This controls:

- Dashboard Info pages (Talkgroups, Bridges, Verified Servers)
- JSON data refresh during upgrades
- Token status / verified-server reporting

**FreeSTAR default operators:** no changes needed.

**Regional or coordinated API setups:** edit the INI after coordinating with the FreeSTAR team.

**Full guide:** [NETWORK_CONFIG.md](NETWORK_CONFIG.md)

### Quick edit

```bash
sudo nano /etc/rysen/systemx-network.ini
```

### Presentation vs network settings

| Purpose | Location |
|---------|----------|
| API URLs, network name, verified-server API | `/etc/rysen/systemx-network.ini` |
| Logos, social links, marquee, footer | `/var/www/html/dashboard/config/` |
| Homepage layout and tile images | `/var/www/html/index.html`, `images/` |

Do **not** remove FreeSTAR branding without explicit approval (see [README.md](README.md)).

### Upgrade safety

A single upgrade:

- Seeds `systemx-network.ini` if missing (FreeSTAR defaults)
- Preserves existing INI, dashboard config, and custom web assets
- Refreshes JSON files only when stale (>7 days) or missing

See [NETWORK_CONFIG.md](NETWORK_CONFIG.md#upgrade-behaviour) for preservation details.

---

## Upgrade Management

### Recommended workflow

1. **Preview:** `systemx-upgrade-dryrun` or menu → Maintenance → Preview Upgrade
2. **Backup:** automatic smart backup to `/opt/backups/`
3. **Upgrade:** menu → Maintenance → Full System Upgrade, or deploy menu **[2] Upgrade**

```bash
sudo ./systemx-deploy.sh
# Select [2] Upgrade System-X
```

The upgrade process creates a backup, downloads the latest installer, updates components while preserving configuration, and runs health checks.

### Rollback

Automatic backups are created before each upgrade. Restore from `/opt/backups/` if needed (menu → Rollback to Backup).

---

## Migrating from v1.3.x

1. Run `sudo ./systemx-deploy.sh`
2. Navigate to **[4] Utilities** → **[8] Migrate from v1.3.x**
3. Follow the automated migration process

### What Gets Updated

- All control scripts (menu, systemx-upgrade, systemx-check-updates)
- Docker Compose upgraded to v2
- Version tracking system initialized

### What Remains Unchanged

- All configuration files (rysen.cfg, rules.py, proxy.cfg)
- `systemx-network.ini` (seeded with FreeSTAR defaults if missing)
- All passwords, credentials, data, and logs
- Docker volumes and networks
- Custom artwork and configurations (`dashboard/config/`, `index.html`, `images/`, `dashboard/img/`)

An automatic backup is created at `/opt/backups/pre-v14-migration-[timestamp]/` before migration starts.

---

## Utilities Menu

Access via **[4] Utilities** in the main menu:

| Utility | Description |
|---------|-------------|
| **Backup Configuration** | Timestamped backup at `/opt/backups/systemx-backup-YYYYMMDD-HHMMSS.tar.gz` |
| **Restore from Backup** | Lists and restores previous backups |
| **View System Logs** | Display and filter System-X logs |
| **Docker Status** | Container health, CPU/memory usage |
| **Network Diagnostics** | Test GitHub connectivity, DNS resolution |
| **Disk Usage Report** | Filesystem and Docker disk usage |
| **Registration** | Register installation with FreeSTAR Network |
| **Migrate from v1.3.x** | Automated migration preserving data and configurations |
| **Repair Broken System** | Reinstall control scripts and run system repair |

---

## Uninstallation

```bash
sudo ./systemx-deploy.sh
# Select [3] Uninstall System-X
```

The uninstaller creates a backup, stops containers, optionally preserves configuration, and cleans up services. Backups remain in `/opt/backups/`.

---

## Troubleshooting

### Token Validation Fails

**"Cannot access repository"**
- Verify token has not expired and has `repo` scope
- Contact administrator for a new token

**"Invalid token format"**
- Classic tokens start with `ghp_`
- Fine-grained tokens start with `github_pat_`

### Network Issues

**"Cannot reach github.com" or "Cannot reach GitHub API"**
- Check internet connection and firewall settings
- Test with: `curl https://github.com`

### Docker Issues

**"Docker not found" or "Docker Compose not found"**
- Install Docker: `sudo apt install docker.io`
- Install Docker Compose v2: `sudo apt install docker-compose-plugin`
- Verify: `docker --version && docker compose version`

### SSH Access Issues

- Verify keys: `cat ~/.ssh/authorized_keys`
- Check permissions: `ls -la ~/.ssh/`
- Ensure SSH is running: `sudo systemctl status ssh`

### Installation Already Exists

The script detects existing installations and offers backup, upgrade path, or reinstall options.

### Getting Help

```bash
sudo ./systemx-deploy.sh
# [5] System Information
# [4] Utilities → [5] Network Diagnostics
# [7] Help & Documentation
```

Contact **shane@freestar.network** or the FreeSTAR Network Discord for support.

---

## Security Considerations

### Token Security

- Never commit tokens to version control
- Use token expiration in GitHub settings
- Remove from shell history: `unset GITHUB_TOKEN`
- A compromised token will result in immediate revocation

### System Security

- Change default System-X passwords immediately after install
- Use SSH key authentication only
- Allow FreeSTAR admin access for support
- Keep OS and Docker updated

### Backups

- Regular automated backups recommended
- Test restore process periodically
- Retain at least 3–5 recent backups

---

## File Locations

| Path | Purpose |
|------|---------|
| `/opt/RYSEN` | Application installation directory |
| `/opt/backups` | Backup archives |
| `/etc/rysen` | Configuration files (including `systemx-network.ini`) |
| `/var/log/rysen` | System logs |
| `/var/www/html/dashboard` | Web dashboard files |

---

## Documentation Index

| Document | Audience | Contents |
|----------|----------|----------|
| [README.md](README.md) | Prospective operators | Authorization, requirements, contact |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Operators | This guide — install, upgrade, utilities |
| [NETWORK_CONFIG.md](NETWORK_CONFIG.md) | Operators | `systemx-network.ini` reference |
| [CHANGELOG.md](CHANGELOG.md) | All | Release notes |

---

**Support:** shane@freestar.network | FreeSTAR Network Discord

**FreeSTAR System-X — Professional DMR Networking for Ham Radio**

*For authorized system operators only.*

Copyright © 2021-2026 Shane Daley, M0VUB
