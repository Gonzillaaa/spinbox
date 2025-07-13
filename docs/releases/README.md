# Spinbox Releases

This directory contains release notes for all Spinbox versions.

## Latest Release

**[v0.1.0-beta.4](v0.1.0-beta.4.md)** - January 13, 2025
- 🐛 Fixed critical update command and version parsing errors
- 🧪 Added comprehensive installation test infrastructure  
- 🔧 Improved shell compatibility and installation detection
- ✅ All 64 tests passing

## Previous Releases

**v0.1.0-beta.2** - Foundation release
- Initial CLI implementation with core functionality
- Component generators and profiles system
- DevContainer and Docker Compose generation

## Installation

**Latest release (v0.1.0-beta.4):**

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

- [v0.1.0-beta.4](v0.1.0-beta.4.md) - Bug fixes and test infrastructure
- v0.1.0-beta.2 - Foundation release (notes not archived)

## Links

- [GitHub Releases](https://github.com/Gonzillaaa/spinbox/releases)
- [Release Process Documentation](../dev/release-process.md)