# Spinbox Installation Guide

Complete guide for installing Spinbox on different platforms and environments.

## Overview

Spinbox is a global CLI tool that creates containerized prototyping environments with predefined profiles or custom component selection. This guide covers all installation methods and troubleshooting.

## Prerequisites

Before installing Spinbox, ensure you have:

- **Git**: Required for installation and project initialization
- **Docker Desktop**: Required for DevContainer support and service orchestration
- **DevContainer-compatible editor**: VS Code, Cursor, or similar for optimal experience
- **Bash shell**: macOS and Linux have this by default; Windows users should use WSL2

### Platform Requirements

| Platform | Minimum Version | Recommended |
|----------|----------------|-------------|
| macOS | 10.15 (Catalina) | 12.0+ (Monterey) |
| Linux | Ubuntu 18.04+ / Similar | Ubuntu 20.04+ |
| Windows | WSL2 | WSL2 with Ubuntu |

## Installation Methods

Choose the method that best fits your environment and preferences:

| Method | Sudo Required | Location | Best For |
|--------|---------------|----------|----------|
| Homebrew | No | `/opt/homebrew/bin` | macOS users with Homebrew |
| System Script | Yes | `/usr/local/bin` | System-wide installations |
| User Script | No | `~/.local/bin` | No sudo access or user-only |
| Manual | Choice | `/usr/local/bin` or `~/.local/bin` | Code review, development, custom setups |

### Method 1: User-Space Installation (Recommended - No sudo required)

**✅ Use when:** You don't have sudo access or prefer user-specific installation

```bash
# One-line user installation (no sudo required)
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install-user.sh | bash
```

**Manual User Installation:**
```bash
# Download and review before running
curl -o install-user.sh https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install-user.sh
chmod +x install-user.sh
./install-user.sh
```

**Note:** After installation, ensure `~/.local/bin` is in your PATH:
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc  # or ~/.zshrc
```

**Verify Installation:**
```bash
spinbox --version
# Should output: Spinbox v0.1.0-beta.2
```

### Method 2: System Installation Script (Requires sudo)

**✅ Use when:** You want system-wide installation and have sudo access

```bash
# One-line installation (requires sudo)
sudo bash <(curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh)
```

**Manual Script Installation:**
```bash
# Download and review before running
curl -o install.sh https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

### Method 3: Homebrew (Advanced Users)

**⚠️ Note:** Direct URL installation is no longer supported by Homebrew. To use Homebrew, you need to create a local tap:

```bash
# Create a local tap (one-time setup)
brew tap-new gonzillaaa/tap
cd $(brew --repository gonzillaaa/tap)
curl -o Formula/spinbox.rb https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/Formula/spinbox.rb

# Install from your tap
brew install gonzillaaa/tap/spinbox
```

**Alternative:** Use the user-space installation instead (recommended).

### Method 4: Manual Installation

**✅ Use when:** You want to inspect the code first or need custom installation

```bash
# Clone repository
git clone https://github.com/Gonzillaaa/spinbox.git
cd spinbox

# Option A: System installation (requires sudo)
chmod +x install.sh
./install.sh

# Option B: User installation (no sudo required)
chmod +x install-user.sh
./install-user.sh

# Optional: Clean up
cd ..
rm -rf spinbox
```

**Benefits of manual installation:**
- Review code before installation
- Choose between system or user installation
- Modify installation scripts if needed
- Keep local copy for development

## Installation Details

### What Gets Installed

**Core Components:**
- `/usr/local/bin/spinbox` - Main CLI executable
- `~/.spinbox/` - Configuration directory
- `~/.spinbox/config/` - Configuration files
- `~/.spinbox/cache/` - Cache directory

**Installation Verification:**
```bash
# Check installation
which spinbox
# Should output: /usr/local/bin/spinbox

# Test basic functionality
spinbox --help
spinbox profiles
```

### Configuration Setup

**Initial Configuration:**
```bash
# Interactive setup (optional)
spinbox config --setup

# Manual configuration
spinbox config --set PYTHON_VERSION=3.12
spinbox config --set NODE_VERSION=20
spinbox config --set PROJECT_AUTHOR="Your Name"
```

**Configuration File Location:**
- Global config: `~/.spinbox/config/global.conf`
- User preferences: `~/.spinbox/config/user.conf`

## Platform-Specific Instructions

### macOS Installation

**Prerequisites:**
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Docker Desktop
brew install --cask docker
```

**Install Spinbox:**
```bash
# Recommended method
brew install https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/Formula/spinbox.rb

# Alternative: Install script
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh | bash
```

### Linux Installation

**Prerequisites (Ubuntu/Debian):**
```bash
# Update package manager
sudo apt update

# Install required packages
sudo apt install -y git curl bash

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Log out and back in, or run:
newgrp docker
```

**Install Spinbox:**
```bash
# Using install script
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh | bash

# Add to PATH if needed (usually automatic)
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Windows (WSL2) Installation

**Prerequisites:**
1. Install WSL2 with Ubuntu distribution
2. Install Docker Desktop for Windows with WSL2 backend

**In WSL2 Terminal:**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install prerequisites
sudo apt install -y git curl bash

# Install Spinbox
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh | bash
```

## Docker Desktop Setup

### Installation

**macOS:**
```bash
brew install --cask docker
# Or download from: https://docs.docker.com/desktop/mac/install/
```

**Windows:**
- Download from: https://docs.docker.com/desktop/windows/install/
- Ensure WSL2 backend is enabled

**Linux:**
```bash
# Install Docker Engine
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
```

### Verification

```bash
# Check Docker is running
docker --version
docker-compose --version

# Test Docker functionality
docker run hello-world
```

## DevContainer Editor Setup

### VS Code

**Installation:**
```bash
# macOS
brew install --cask visual-studio-code

# Or download from: https://code.visualstudio.com/
```

**Required Extensions:**
- Dev Containers (ms-vscode-remote.remote-containers)
- Docker (ms-azuretools.vscode-docker)

### Cursor

**Installation:**
- Download from: https://cursor.sh/
- Supports same DevContainer extensions as VS Code

## Post-Installation

### Initial Setup

**1. Verify Installation:**
```bash
spinbox --version
spinbox profiles
spinbox status
```

**2. Create First Project:**
```bash
# Quick test with minimal project
spinbox create test-project --python
cd test-project

# Open in editor
code .  # VS Code
cursor . # Cursor
```

**3. Configure Global Settings:**
```bash
spinbox config --setup
# Or manually:
spinbox config --set PROJECT_AUTHOR="Your Name"
spinbox config --set PROJECT_EMAIL="your.email@example.com"
```

### Configuration Options

**Essential Configuration:**
```bash
# Software versions
spinbox config --set PYTHON_VERSION=3.12
spinbox config --set NODE_VERSION=20
spinbox config --set POSTGRES_VERSION=15

# Project defaults
spinbox config --set PROJECT_AUTHOR="Your Name"
spinbox config --set PROJECT_LICENSE=MIT

# User preferences
spinbox config --set PREFERRED_EDITOR=code
spinbox config --set AUTO_START_SERVICES=true
```

## Troubleshooting

### Common Issues

**1. Command Not Found**
```bash
# Check if binary exists
ls -la /usr/local/bin/spinbox

# Check PATH
echo $PATH

# Add to PATH if needed
export PATH="/usr/local/bin:$PATH"
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
```

**2. Permission Denied**
```bash
# Make executable
chmod +x /usr/local/bin/spinbox

# Check ownership
ls -la /usr/local/bin/spinbox

# Fix ownership if needed (macOS/Linux)
sudo chown $USER:$USER /usr/local/bin/spinbox
```

**3. Docker Issues**
```bash
# Check Docker status
docker --version
docker ps

# Start Docker Desktop (macOS/Windows)
open -a Docker  # macOS

# Start Docker service (Linux)
sudo systemctl start docker
sudo systemctl enable docker
```

**4. Configuration Problems**
```bash
# Check configuration
spinbox config --list

# Reset configuration
spinbox config --reset global
spinbox config --setup
```

### Installation Verification

**Complete Verification Script:**
```bash
#!/bin/bash
echo "=== Spinbox Installation Verification ==="

# Check Spinbox
echo "1. Checking Spinbox installation..."
if command -v spinbox &> /dev/null; then
    echo "✓ Spinbox found: $(which spinbox)"
    echo "✓ Version: $(spinbox --version)"
else
    echo "✗ Spinbox not found in PATH"
fi

# Check Docker
echo "2. Checking Docker..."
if command -v docker &> /dev/null; then
    echo "✓ Docker found: $(docker --version)"
else
    echo "✗ Docker not found"
fi

# Check Git
echo "3. Checking Git..."
if command -v git &> /dev/null; then
    echo "✓ Git found: $(git --version)"
else
    echo "✗ Git not found"
fi

# Test Spinbox functionality
echo "4. Testing Spinbox functionality..."
if spinbox profiles > /dev/null 2>&1; then
    echo "✓ Spinbox profiles command works"
else
    echo "✗ Spinbox profiles command failed"
fi

echo "=== Verification Complete ==="
```

### Getting Help

**Documentation:**
- Main README: [GitHub Repository](https://github.com/Gonzillaaa/spinbox)
- Troubleshooting: [docs/troubleshooting.md](./troubleshooting.md)
- Quick Start: [docs/quick-start.md](./quick-start.md)

**Community:**
- Issues: [GitHub Issues](https://github.com/Gonzillaaa/spinbox/issues)
- Discussions: [GitHub Discussions](https://github.com/Gonzillaaa/spinbox/discussions)

**CLI Help:**
```bash
spinbox --help
spinbox create --help
spinbox config --help
```

## Uninstallation

Spinbox provides multiple uninstallation methods depending on how it was installed.

### Method 1: Using Spinbox CLI (Recommended)

If Spinbox is working correctly, use the built-in uninstall command:

```bash
# Remove Spinbox binary only (preserves configuration)
spinbox uninstall

# Remove Spinbox and configuration files
spinbox uninstall --config

# Remove everything (same as --config)
spinbox uninstall --all

# Dry-run to see what would be removed
spinbox uninstall --dry-run --config

# Force removal without confirmation
spinbox uninstall --force --config
```

### Method 2: Standalone Uninstall Script

If the CLI is corrupted or unavailable, use the standalone script:

```bash
# Basic uninstall (binary only)
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/uninstall.sh | bash

# Remove everything including configuration
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/uninstall.sh | bash -s -- --config

# Force removal without prompts
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/uninstall.sh | bash -s -- --config --force

# Dry-run to see what would be removed
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/uninstall.sh | bash -s -- --dry-run --config
```

### Method 3: Homebrew Method

For Homebrew installations:

```bash
brew uninstall spinbox
```

**Note**: This only removes the binary. To remove configuration files:
```bash
rm -rf ~/.spinbox
```

### Method 4: Manual Removal

Complete manual cleanup if other methods fail:

```bash
# Remove binary (try common locations)
sudo rm -f /usr/local/bin/spinbox
sudo rm -f /opt/homebrew/bin/spinbox
rm -f ~/.local/bin/spinbox

# Remove configuration (optional)
rm -rf ~/.spinbox

# Remove from PATH if manually added
# Edit ~/.bashrc, ~/.zshrc, or ~/.profile and remove spinbox PATH entries
```

### Uninstall Options

| Option | Binary | Configuration | Use Case |
|--------|--------|---------------|----------|
| `spinbox uninstall` | ✅ Removed | ❌ Preserved | Keep settings for reinstall |
| `spinbox uninstall --config` | ✅ Removed | ✅ Removed | Complete removal |
| Homebrew method | ✅ Removed | ❌ Preserved | Homebrew installations |
| Manual removal | ✅ Removed | ⚠️ Optional | Last resort |

### What Gets Removed

**Spinbox Binary:**
- `/usr/local/bin/spinbox` (most installations)
- `/opt/homebrew/bin/spinbox` (Homebrew on Apple Silicon)
- `~/.local/bin/spinbox` (user installations)

**Configuration Files (if --config used):**
- `~/.spinbox/config/` - All configuration files
- `~/.spinbox/cache/` - Cache directory
- `~/.spinbox/` - Entire configuration directory

**Preserved by Default:**
- Project files created with Spinbox
- Docker images and containers
- DevContainer configurations in projects

## Next Steps

After successful installation:

1. **Read Quick Start Guide**: [docs/quick-start.md](./quick-start.md)
2. **Explore Profiles**: `spinbox profiles`
3. **Create First Project**: `spinbox create myproject --profile web-app`
4. **Configure Preferences**: `spinbox config --setup`

## Version Updates

### Built-in Update Command (Recommended)
```bash
# Check for updates
spinbox update --check

# Update to latest version
spinbox update

# Update to specific version
spinbox update --version 1.2.0

# Force update with no prompts
spinbox update --force --yes
```

### Homebrew Updates
```bash
# Update Homebrew
brew update

# Upgrade Spinbox
brew upgrade spinbox

# Or reinstall latest version
brew uninstall spinbox
brew install https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/Formula/spinbox.rb
```

### Manual Updates
```bash
# Use built-in update command (recommended)
spinbox update

# Or re-run installation script
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh | bash
```

---

**Installation complete!** Start creating prototyping environments with `spinbox create myproject --profile web-app`.