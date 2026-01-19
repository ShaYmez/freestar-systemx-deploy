# FreeSTAR System-X (Stack)
**RYSEN DMRMaster+ Docker Deployment and Management Install**

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Version](https://img.shields.io/badge/version-1.4.0-green.svg)
![Platform](https://img.shields.io/badge/platform-Debian%20%7C%20Ubuntu-orange.svg)

**Professional DMR Network Platform for Ham Radio Operators**

FreeSTAR System-X is a comprehensive, enterprise-grade DMR network platform designed for the amateur radio community. Built on proven open-source technologies and powered by **RYSEN DMRMaster+**, it provides system operators with a robust, professionally supported infrastructure for building high-quality DMR networks.

![FreeSTAR System-X](screenshot.png)

## Table of Contents

- [Quick Start (Authorized Operators)](#quick-start-authorized-operators)
- [Installation Instructions](#installation-instructions)
- [What is FreeSTAR System-X?](#what-is-freestar-system-x)
- [Why Choose System-X?](#why-choose-system-x)
- [Authorization Criteria](#authorization-criteria-for-system-operators)
- [System Requirements](#system-requirements)
- [Getting Authorized](#getting-authorized)
- [Documentation](#documentation)
- [Support](#support)
- [License](#license)

## Quick Start (Authorized Operators)

Already authorized?  Get started in minutes:

```bash
cd /opt
git clone https://github.com/ShaYmez/freestar-systemx-deploy.git
cd freestar-systemx-deploy
sudo ./systemx-deploy.sh
```

**📖 Complete Installation Guide:** [DEPLOYMENT.md](DEPLOYMENT.md)

## Installation Instructions

**Before you begin**, please read the complete deployment guide: 

### [DEPLOYMENT.md - Full Installation Guide](DEPLOYMENT.md)

The deployment guide includes:
- **Pre-Installation Setup** - System preparation, Docker installation, SSH security configuration
- **Step-by-Step Installation** - Complete deployment walkthrough
- **Security Configuration** - SSH keys, FreeSTAR admin access, firewall setup
- **Utilities & Management** - Backup, restore, diagnostics, upgrades
- **Troubleshooting** - Common issues and solutions
- **Migration Guide** - Upgrading from v1.3.x installations

**Important:** Complete all pre-installation steps in DEPLOYMENT.md before running the deployment script to ensure proper security and administrative access. 

## What is FreeSTAR System-X?

FreeSTAR System-X delivers a complete DMR master server stack using **RYSEN DMRMaster+** and other software packages bundled together with Docker. The platform combines powerful features with ease of management reliability and global connectivity:

- **Full-featured Server Management** - Comprehensive control over your DMR master server
- **Real-time Dashboard & Analytics** - Monitor activity, connections, and performance
- **Multi-site Network Coordination** - Seamlessly connect wth OpenBridge to other master servers
- **Automated Updates & Maintenance** - Secure GitHub token-based update system
- **Professional Support** - Backed by the experienced FreeSTAR team

The platform is designed to help system operators build and maintain high-quality DMR networks that serve their communities effectively.

## Why Choose System-X?

### Enterprise-Grade Reliability
Built on Docker containerization with proven stability for 24/7 operation.  Automated health checks and monitoring ensure your network stays online.

### Automated Management
One-command deployment, automated updates, and built-in backup/restore utilities reduce maintenance overhead. Spend less time managing infrastructure and more time serving your community.

### Professional Support Network
Join a community of experienced system operators. Get help from the FreeSTAR team and benefit from collective knowledge and best practices.

### Secure & Controlled
GitHub token-based authentication ensures only authorized operators receive updates.  SSH key-based administration provides secure remote management.

### Network Consistency
Standardized configurations across all System-X installations ensure compatibility and seamless inter-network communication. Users get a consistent experience across the FreeSTAR network.

### Active Development
Regular updates, security patches, and new features. System-X continues to evolve with the needs of the amateur radio DMR community.

## Authorization Criteria for System Operators

FreeSTAR System-X is available to qualified system operators who meet specific criteria.  Authorization demonstrates commitment to network quality, security, and community standards.

### Required Qualifications

#### Technical Responsibility
- Proven track record in amateur radio operations or network management
- Understanding of DMR technology and best practices
- Commitment to maintaining high service availability and uptime

#### Administrative Access & Security
- **Provide FreeSTAR administrators with root SSH access** for system updates, security patches, and maintenance
- **Use secure SSH key authentication only** - password authentication is not permitted
- Maintain system security best practices and keep systems properly configured
- This ensures timely security patches, platform improvements, and network-wide consistency

#### Professional Server Hosting
- **VPS or enterprise-grade dedicated server required** (No home-based installations)
- Dedicated fixed IP address
- Professional hosting ensures reliability, uptime, and bandwidth consistency
- Home internet connections lack the stability and uptime requirements for professional DMR network operation

#### Branding & Identity
- Do not modify dashboard branding, logos, or FreeSTAR System-X identity
- Maintain consistent user experience across the network
- Represent FreeSTAR System-X professionally in your community

#### Network Standards
- Follow FreeSTAR System-X configuration standards
- Maintain compatibility with network-wide updates
- Coordinate with FreeSTAR team on major configuration changes

#### Community Leadership
- Active participation in the ham radio DMR community
- Foster positive relationships with users and other system operators
- Provide support and guidance to your local community
- Actively promote FreeSTAR System-X in your ham radio communities

#### Minimum Hardware
- Meet the hardware specifications outlined below
- Ensure reliable internet connectivity with adequate bandwidth
- Maintain proper hosting environment with monitoring

## System Requirements

### Supported Operating Systems

- **Debian:** 11, 12, 13
- **Ubuntu:** 22.04 LTS, 24.04 LTS

### Minimum Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **Hosting** | VPS or dedicated server | Enterprise-grade VPS/dedicated |
| **CPU** | 2 cores | 4+ cores |
| **RAM** | 2 GB | 4+ GB |
| **Disk Space** | 20 GB free | 40+ GB SSD |
| **Network** | Fixed IP, stable connection | Dedicated IP, high-speed connection |

**Important:** Home-based installations are not permitted. Professional hosting (VPS or dedicated server) is required to ensure network reliability, consistent uptime, and adequate bandwidth for DMR network operations.

### Software Requirements

- Root or sudo access
- Docker and Docker Compose v2
- Git and curl
- Active internet connection with GitHub access
- GitHub Personal Access Token (provided by FreeSTAR admin team after authorization)

**Note:** The GitHub token is used for secure authentication when downloading updates and authorized System-X components.

**📘 See [DEPLOYMENT.md](DEPLOYMENT.md) for complete pre-installation and setup instructions.**

## Getting Authorized

Interested in becoming an authorized FreeSTAR System-X operator?

### Application Process

#### 1. Contact Us
Email **shane@freestar.network** with the following information:

- Your amateur radio callsign
- Brief description of your experience in amateur radio and/or network operations
- Information about your proposed installation (hosting provider, server specs, location)
- Coverage area you intend to serve
- Your commitment to meeting the authorization criteria above

#### 2. Join the Community
Connect with us on the **[FreeSTAR Network Discord server](https://discord.gg/TD5tKyqFPR)**

Meet other system operators, ask questions, and stay updated on network developments.

#### 3. Authorization Review
The FreeSTAR team will review your application and discuss:
- Your qualifications and experience
- Technical requirements and hosting setup
- Authorization criteria and expectations
- Timeline for deployment

#### 4. Deployment
Once authorized, you'll receive:
- **GitHub Personal Access Token** for authenticated updates
- **Deployment script and documentation** - Follow [DEPLOYMENT.md](DEPLOYMENT.md) for installation
- **Access to FreeSTAR Network resources** and support channels
- **Direct support from the FreeSTAR team** during deployment

## Documentation

- **[DEPLOYMENT.md - Complete Installation Guide](DEPLOYMENT.md)** - Pre-installation setup, security configuration, Docker installation, step-by-step deployment, utilities, troubleshooting, and migration guide
- **[Wiki](#)** - Coming soon - comprehensive guides and documentation
- **[Changelog](#)** - Coming soon - release notes and version history

## Support

### Contact Information

- **Email**: shane@freestar.network
- **Discord**: [FreeSTAR Network Discord Server](https://discord.gg/TD5tKyqFPR)
- **GitHub Issues**:  For bug reports and feature requests

For technical support, deployment questions, or authorization inquiries, please reach out through any of these channels. The FreeSTAR team is committed to helping qualified operators succeed.

### Getting Help

The deployment script includes built-in diagnostics and help:

```bash
./systemx-deploy.sh
# Select [7] Help & Documentation
# Or [4] Utilities → [5] Network Diagnostics
```

**For installation help, see [DEPLOYMENT.md](DEPLOYMENT.md)**

## Version Information

- **Current Version**: 1.4.0
- **Release Date**: January 15, 2026
- **Supported Installer**: System-X-Installer v1.4.0+

## License

Copyright © 2021-2026 Shane Daley, M0VUB

Licensed under the MIT License.  See LICENSE file for details.

---

**FreeSTAR System-X - Professional DMR Networking for Ham Radio**

*For authorized system operators only.*
