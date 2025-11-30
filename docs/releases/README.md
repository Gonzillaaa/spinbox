# Spinbox Releases

This directory contains release notes for all Spinbox versions.

## Latest Release

**[v0.1.0-beta.8](v0.1.0-beta.8.md)** - November 2024
- 🔧 Alpine container compatibility fixes
- 🎯 Cursor/VS Code server support improvements
- 📦 Added procps and bash packages for DevContainer compatibility

## Previous Releases

**[v0.1.0-beta.7](v0.1.0-beta.7.md)** - October 1, 2025
- 🎯 Git hooks integration (pre-commit, pre-push)
- ✅ Automatic code quality gates for Python projects

**[v0.1.0-beta.6](v0.1.0-beta.6.md)** - October 1, 2025
- 🎯 Git hooks feature (15 SP) + quality improvements (13 SP)
- 🔒 Comprehensive security audit
- ⚡ Exceptional performance profiling
- 📝 Edge cases testing and documentation

**[v0.1.0-beta.5](v0.1.0-beta.5.md)** - July 19, 2025
- 🚀 Automatic dependency management with --with-deps flag
- 📦 TOML-based dependency templates for Python and Node.js
- 🎯 Smart conflict detection and setup script generation

**v0.1.0-beta.2** - Foundation release
- Initial CLI implementation with core functionality
- Component generators and profiles system
- DevContainer and Docker Compose generation

## Installation

**Latest release (v0.1.0-beta.8):**

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

- [v0.1.0-beta.8](v0.1.0-beta.8.md) - Alpine container compatibility
- [v0.1.0-beta.7](v0.1.0-beta.7.md) - Git hooks integration
- [v0.1.0-beta.6](v0.1.0-beta.6.md) - Quality improvements and comprehensive testing
- [v0.1.0-beta.5](v0.1.0-beta.5.md) - Automatic dependency management
- [v0.1.0-beta.4](v0.1.0-beta.4.md) - Bug fixes and test infrastructure
- v0.1.0-beta.2 - Foundation release (notes not archived)

## Links

- [GitHub Releases](https://github.com/Gonzillaaa/spinbox/releases)
- [Release Process Documentation](../dev/release-process.md)