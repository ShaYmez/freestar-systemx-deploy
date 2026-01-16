# Changelog

All notable changes to System-X Installer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.0] - 2026-01-15

### Added
- **Public Deployment System**: New token-based deployment engine (`deployment/systemx-deploy.sh`) for secure remote updates
- **Multilingual Support**: Complete language system with 11 languages (English, Spanish, Portuguese, German, Dutch, Italian, Portuguese, Chinese, Russian, Arabic, Japanese), menu driven with locale support.
- **Unified Control Scripts**: New `systemx-common` shared library consolidating all control script functionality
- **Hierarchical Menu System**: Reorganized menu with service control, configuration, updates, and utilities submenus
- **Configuration Editor**: New `systemx-config` tool for editing all configuration files
- **Service Control**: Unified `systemx-service` script for start/stop/restart/flush operations
- **Migration Tool**: Automated migration from v1.3.x to v1.4.0 with configuration preservation
- **Uninstall Capability**: Complete system removal with backup options
- **Dashboard Updates**: Refreshed HTML, CSS, and JavaScript with modern styling and improved UX

### Changed
- **Authentication**: Migrated from SSH to HTTPS with GitHub token authentication
- **Security**: Replaced SQL injection-vulnerable authentication with bcrypt password hashing
- **Docker Compose**: Updated service configurations, fixed d-aprs networking, corrected proxy configs
- **Installation Process**: Streamlined installer with colored output and progress indicators
- **Control Scripts**: All scripts now use shared library for consistency
- **Configuration Management**: Simplified config file handling across all tools

### Security
- Token-based authentication with three priority sources (environment, Docker secret, system file)
- Secure password hashing with bcrypt
- Protected API endpoints
- Safe file operations with parameter expansion guards

### Removed
- SSH-based Git operations
- SQL injection-vulnerable authentication system
- Obsolete RYMonv2 configuration files
- Duplicate code across control scripts

## [1.3.9r3] - Previous Release

Legacy release. See commit history for details.

---

**Full Changelog**: https://github.com/ShaYmez/System-X-Installer/compare/v1.3.9r3...v1.4.0
