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

## Installation

**Choose your preferred method:**

### User Installation (Recommended)
```bash
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install-user.sh | bash
```
- Installs to `~/.local/bin` (no sudo required)
- **Automatic PATH setup** - detects your shell (.zshrc, .bashrc, etc.) and adds `~/.local/bin` to PATH
- Asks permission in interactive mode, automatic in non-interactive mode (`curl | bash`)
- No manual configuration needed

### System Installation
```bash
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh | sudo bash
```
- Installs to `/usr/local/bin` (available system-wide)
- Requires sudo permissions

**Verify Installation:**
```bash
spinbox --version
# Should output: Spinbox v0.1.0-beta.4
```

### Alternative: Manual Installation

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
# Option A: User installation (recommended, automatic PATH setup)
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install-user.sh | bash

# Option B: System installation (requires sudo)
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
# Option A: User installation (recommended, automatic PATH setup)
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install-user.sh | bash

# Option B: System installation (requires sudo)
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh | bash
```

**Note:** The user installation automatically configures your shell profile. For system installation, ensure `/usr/local/bin` is in your PATH.

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

# Install Spinbox (user installation with automatic PATH setup)
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install-user.sh | bash
```

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
# For user installations (~/.local/bin)
ls -la ~/.local/bin/spinbox
echo $PATH | grep -o ~/.local/bin

# For system installations (/usr/local/bin)  
ls -la /usr/local/bin/spinbox
echo $PATH | grep -o /usr/local/bin

# Add to PATH if needed (user installation)
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Add to PATH if needed (system installation)
export PATH="/usr/local/bin:$PATH"
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
```

**Note:** The user installation script should automatically handle PATH setup, but you may need to restart your terminal or run `source ~/.bashrc`.

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

## Uninstallation

### Method 1: Using Spinbox CLI (Recommended)

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

### Method 2: Manual Removal

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

## Next Steps

After successful installation:

1. **Read Quick Start Guide**: [quick-start.md](./quick-start.md)
2. **Explore Profiles**: `spinbox profiles`
3. **Create First Project**: `spinbox create myproject --profile web-app`
4. **Configure Preferences**: `spinbox config --setup`

---

**Installation complete!** Start creating prototyping environments with `spinbox create myproject --profile web-app`.
