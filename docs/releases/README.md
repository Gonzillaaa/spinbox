# Spinbox Releases

This directory contains release notes for all Spinbox versions.

## Latest Release

**[v0.1.0-beta.6](v0.1.0-beta.6.md)** - September 30, 2025
- 🐛 Fixed node profile array handling bug
- ✅ Updated test suite to match new directory structure
- 📊 100% test success rate (77/77 passing)
- 🎯 Enhanced stability and error handling

## Previous Releases

**[v0.1.0-beta.5](v0.1.0-beta.5.md)** - July 19, 2025
- 🚀 Automatic dependency management with --with-deps flag
- 📦 TOML-based dependency templates for Python and Node.js
- 🎯 Smart conflict detection and setup script generation

**v0.1.0-beta.2** - Foundation release
- Initial CLI implementation with core functionality
- Component generators and profiles system
- DevContainer and Docker Compose generation

## Installation

**Latest release (v0.1.0-beta.6):**

**User installation (no sudo required):**
```bash
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install-user.sh | bash
```

**System installation:**
```bash
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh | sudo bash
```

**Update existing installation:**
```bash
spinbox update
```

## Release Archive

- [v0.1.0-beta.6](v0.1.0-beta.6.md) - Stability and bug fixes
- [v0.1.0-beta.5](v0.1.0-beta.5.md) - Automatic dependency management
- [v0.1.0-beta.4](v0.1.0-beta.4.md) - Bug fixes and test infrastructure
- v0.1.0-beta.2 - Foundation release (notes not archived)

## Links

- [GitHub Releases](https://github.com/Gonzillaaa/spinbox/releases)
- [Release Process Documentation](../dev/release-process.md)