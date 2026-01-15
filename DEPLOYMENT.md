# FreeSTAR SystemX Deployment Tool

**Deployment for FreeSTAR SystemX installations**

This repository contains `systemx-deploy.sh`, a comprehensive deployment and management tool for authorised System-X installations. It provides automated installation, upgrades, backups, and system utilities through an interactive menu interface.

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

### Prerequisites
- Root or sudo access
- Docker and Docker Compose v2
- Git installed
- Network connectivity to github.com and GitHub API

## Quick Start

### 1. Download the Deployment Script

```bash
# Obtain systemx-deploy.sh from your System-X administrator
# Contact: shane@freestar.network
chmod +x systemx-deploy.sh
```

### 2. Run as Root

```bash
sudo ./systemx-deploy.sh
```

### 3. Follow the Interactive Menu

The script presents an interactive menu with the following options:

| Option | Function |
|--------|----------|
| **[1]** | Install System-X (fresh installation) |
| **[2]** | Upgrade System-X (existing installation) |
| **[3]** | Uninstall System-X |
| **[4]** | Utilities (backup, restore, diagnostics) |
| **[5]** | System Information |
| **[6]** | Validate Token |
| **[7]** | Help & Documentation |
| **[0]** | Exit |

## Authentication

System-X installations require a **GitHub Personal Access Token (PAT)** for repository access.

### Obtaining a Token

1. Contact your FreeSTAR SystemX administrator
2. They will generate a Personal Access Token with appropriate permissions

### Token Formats

The script accepts two token formats:
- **Classic:** `ghp_` followed by 36 characters
- **Fine-grained:** `github_pat_` followed by additional characters

### Token Validation

The script automatically validates your token with the github api engine

## Installation Process

### Step-by-Step

1. **System Checks**
   - Verifies OS compatibility
   - Checks network connectivity
   - Validates root access

2. **Token Validation**
   - Prompts for GitHub PAT if needed
   - Validates format and API access
   - Tests repository permissions

3. **Repository Cloning**
   - Downloads the official installer from GitHub
   - Sets up installation working directory

4. **Installer Execution**
   - Runs the native System-X installer
   - Presents deployment mode options (Local or Production)
   - Configures Docker services
   - Initializes configuration files

5. **Cleanup**
   - Removes temporary files
   - Secures token from memory
   - Displays completion status

### What Gets Installed

- Docker containers and services
- RYSEN DMRMaster+
- System-X monitoring dashboard
- RYSEN control scripts
- Configuration templates
- Database initialization
- Web server configuration

## Utilities Menu

The Utilities section provides system management tools:

### Backup Configuration
Creates timestamped backup of all configurations and logs:
- Saves to `/opt/backups/systemx-backup-YYYYMMDD-HHMMSS.tar.gz`
- Includes configuration files and log archives
- Generates restore instructions manifest

### Restore from Backup
Restores a previous backup:
- Lists available backups
- Validates backup integrity
- Restores configuration and logs
- Verifies restoration success

### View System Logs
- Display System-X logs
- Filter by service or time range
- Search for error patterns
- Export logs for analysis

### Docker Status
- Show running containers
- Display container health status
- CPU and memory usage
- Network information

### Network Diagnostics
- Test GitHub connectivity
- Verify GitHub API access
- Check Docker Hub access
- Display network interfaces
- Test DNS resolution

### Disk Usage Report
- Overall filesystem usage
- System-X configuration size
- Log file size
- Docker disk consumption

### Registration
- Register installation with FreeSTAR Network
- Link installation to operator account
- Verify authorization status

## System Information

Displays comprehensive system details:
- OS distribution and version
- Hardware specifications
- Network configuration (local/external IP)
- System-X installation status
- Docker version and running containers
- Authorization status

## Upgrade Management

### Check for Updates
```bash
./systemx-deploy.sh
# Select [2] Upgrade System-X
```

### Upgrade Process
- Creates automatic backup
- Downloads latest System-X installer
- Updates all components
- Preserves configuration and data
- Performs health check after upgrade

### Rollback
If issues arise after upgrade:
- Automatic backups created before each upgrade
- Restore previous version from backup
- Verify service health after rollback

## Migrating from v1.3.x

If you have an existing System-X v1.3.x installation:

1. Download the deployment script (same process as fresh installation)
2. Run as root: `sudo ./systemx-deploy.sh`
3. Navigate to **[4] Utilities** → **[8] Migrate from v1.3.x**
4. Follow the automated migration process

The migration preserves all your data and configurations while updating the system to v1.4.0.

### What Gets Updated During Migration

- All control scripts (menu, systemx-upgrade, systemx-check-updates, etc.)
- Docker Compose upgraded to v2
- Version tracking system initialized
- Update/upgrade capabilities enabled

### What Remains Unchanged

- All configuration files (rysen.cfg, rules.py, proxy.cfg)
- All passwords and credentials
- All data and logs
- Docker volumes and networks
- Custom artwork and configurations and marquee

### Automatic Backup

Before migration starts, an automatic backup is created at:
```
/opt/backups/pre-v14-migration-[timestamp]/
```

If anything goes wrong, you can manually restore from this backup.

## Uninstallation

### Complete Removal
```bash
./systemx-deploy.sh
# Select [3] Uninstall System-X
```

### What Happens
- Automatic backup created before removal
- Docker containers stopped and removed
- Configuration directories preserved (optional)
- System-X services disabled
- Temporary files cleaned up

### Recovery
- Backups retained in `/opt/backups/`
- Can restore at any time with utilities
- Docker images can be reinstalled

## Troubleshooting

### Token Validation Fails

**Error: "Cannot access repository"**
- Verify token has been provided
- Check token has not expired
- Confirm token has 'repo' scope permission
- Contact administrator for new token

**Error: "Invalid token format"**
- Classic tokens start with `ghp_`
- Fine-grained tokens start with `github_pat_`
- Verify exact token from administrator
- No spaces or special characters

### Network Issues

**Error: "Cannot reach github.com"**
- Check internet connection
- Verify firewall allows outbound HTTPS
- Test with: `curl https://github.com`
- Contact network administrator

**Error: "Cannot reach GitHub API"**
- Similar to above
- GitHub API may be temporarily unavailable
- Retry after a few minutes

### Docker Not Found

**Error: "Docker not found" or "Docker Compose not found"**
- Install Docker: `apt install docker.io`
- Install Docker Compose v2: `apt install docker-compose`
- Verify: `docker --version && docker-compose --version`
- Add user to docker group if needed

### Installation Already Exists

- Script detects existing installation
- Offers to create backup before reinstalling
- Allows upgrade path instead of fresh install
- All data can be preserved

## Security Considerations

### Token Security
- Never commit tokens to version control
- Remove tokens from shell history: `unset GITHUB_TOKEN`
- Tokens are overwritten in memory after use
- Use token expiration in GitHub settings
- Store your Token in a safe place or vault
- A compromised token will result in an instant ban!! Be warned!!
- Always be resposible for your token and the security of your server!!

### System Security
- Run installer as root (required for system-wide configuration)
- Change default System-X passwords immediately after install
- Maintain firewall restrictions
- Keep OS and Docker updated
- Monitor access logs regularly

### Backups
- Regular automated backups recommended
- Store backups in secure location
- Test restore process periodically
- Retain at least 3-5 recent backups

## File Locations

After installation, System-X creates these directories:

| Path | Purpose |
|------|---------|
| `/opt/RYSEN` | Application installation directory |
| `/etc/rysen` | Configuration files |
| `/var/log/rysen` | System logs |
| `/opt/backups` | Backup archives |
| `/var/www/html/dashboard` | Web dashboard files |

## Getting Help

Contact FreeSTAR administrator

### Check System Information
```bash
./systemx-deploy.sh
# Select [5] System Information
```

### Run Diagnostics
```bash
./systemx-deploy.sh
# Select [4] Utilities → [5] Network Diagnostics
```

### View Help
```bash
./systemx-deploy.sh
# Select [7] Help & Documentation
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

## Wiki

Comming soon....

---

**For authorized system operators only.**

---

**Copyright © 2021-2026 Shane Daley, M0VUB**
