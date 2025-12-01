# Installation Guide

## Prerequisites

- **Git**: For installation and project initialization
- **Docker Desktop**: For DevContainer and service orchestration
- **DevContainer editor**: VS Code, Cursor, or similar

| Platform | Minimum | Recommended |
|----------|---------|-------------|
| macOS | 10.15 (Catalina) | 12.0+ (Monterey) |
| Linux | Ubuntu 18.04+ | Ubuntu 20.04+ |

## Installation

### User Installation (Recommended)
```bash
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install-user.sh | bash
```
- Installs to `~/.local/bin` (no sudo required)
- Automatic PATH setup

### System Installation
```bash
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh | sudo bash
```
- Installs to `/usr/local/bin`
- Requires sudo

### Manual Installation
```bash
git clone https://github.com/Gonzillaaa/spinbox.git
cd spinbox
./install-user.sh  # or ./install.sh for system install
```

### Verify
```bash
spinbox --version
# Should output: Spinbox v0.1.0-beta.8
```

## What Gets Installed

- `~/.local/bin/spinbox` or `/usr/local/bin/spinbox` - CLI executable
- `~/.spinbox/runtime/` - Libraries, generators, templates
- `~/.spinbox/config/` - Configuration files

## Platform Setup

### macOS
```bash
# Install Docker Desktop
brew install --cask docker
```

### Linux (Ubuntu/Debian)
```bash
# Install Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker
```

## Post-Installation

```bash
# Test installation
spinbox --version
spinbox profiles

# Create first project
spinbox create test-project --python
cd test-project
code .  # or cursor .
```

### Configure (Optional)
```bash
spinbox config --set PYTHON_VERSION=3.11
spinbox config --set NODE_VERSION=20
spinbox config --set PROJECT_AUTHOR="Your Name"
```

## Updates

```bash
# Check for updates
spinbox update --check

# Update to latest
spinbox update

# Update to specific version
spinbox update --version 1.2.0
```

## Uninstallation

```bash
# Remove binary only
spinbox uninstall

# Remove everything including config
spinbox uninstall --config

# Standalone script (if CLI broken)
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/uninstall.sh | bash -s -- --config
```

## Troubleshooting

### Command Not Found
```bash
# Check PATH
echo $PATH | grep -o ~/.local/bin

# Add to PATH if needed
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Permission Denied
```bash
chmod +x ~/.local/bin/spinbox
```

### Docker Issues
```bash
docker --version
docker ps
# If not running, start Docker Desktop
```

See [Troubleshooting Guide](./troubleshooting.md) for more help.
