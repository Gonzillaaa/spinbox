# Docker Hub Configuration

Spinbox supports using pre-built Docker images from Docker Hub to speed up project creation by 50-70%. This guide explains how to configure Docker Hub integration and use custom repositories.

## Quick Start

To use Docker Hub with default Spinbox images:

```bash
spinbox create myproject --fastapi --docker-hub
spinbox create myapp --nextjs --docker-hub  
spinbox create pyproject --python --docker-hub
```

## Default Configuration

By default, Spinbox uses these optimized base images:

- **Python projects**: `gonzillaaa/spinbox-python-base:latest` (495MB)
- **Node.js projects**: `gonzillaaa/spinbox-node-base:latest` (276MB)

These images include:
- Development tools (git, zsh, oh-my-zsh, powerlevel10k, nano, tree, jq, htop)
- Package managers (UV for Python, npm for Node.js)
- Essential development aliases
- Ready-to-use development environment

## Custom Repository Configuration

You can configure Spinbox to use your own Docker Hub repositories by editing the global configuration file.

### Configuration File Location

```bash
~/.spinbox/global.conf
```

### Configuration Variables

Add these variables to your global configuration:

```bash
# Custom Docker Hub configuration
DOCKER_HUB_USERNAME="mycompany"
SPINBOX_PYTHON_BASE_IMAGE="mycompany/custom-python-base"
SPINBOX_NODE_BASE_IMAGE="mycompany/custom-node-base"
```

### Configuration Examples

#### Example 1: Company Repository
```bash
# ~/.spinbox/global.conf
DOCKER_HUB_USERNAME="acmecorp"
SPINBOX_PYTHON_BASE_IMAGE="acmecorp/python-dev"
SPINBOX_NODE_BASE_IMAGE="acmecorp/node-dev"
```

#### Example 2: Private Registry
```bash
# ~/.spinbox/global.conf
DOCKER_HUB_REGISTRY="my-registry.company.com/v2"
DOCKER_HUB_USERNAME="myteam"
SPINBOX_PYTHON_BASE_IMAGE="myteam/python-base"
SPINBOX_NODE_BASE_IMAGE="myteam/node-base"
```

#### Example 3: Different Base Images
```bash
# ~/.spinbox/global.conf
SPINBOX_PYTHON_BASE_IMAGE="python:3.11-dev"
SPINBOX_NODE_BASE_IMAGE="node:20-alpine-dev"
```

## Creating Custom Base Images

If you want to create your own base images compatible with Spinbox:

### Python Base Image Requirements

```dockerfile
FROM python:3.11-slim

# Install essential development tools
RUN apt-get update && apt-get install -y \
    git curl zsh nano tree jq iputils-ping htop \
    && rm -rf /var/lib/apt/lists/*

# Install UV package manager
RUN pip install --no-cache-dir uv

# Install Oh My Zsh (optional but recommended)
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Set working directory
WORKDIR /workspace

# Keep container running
CMD ["zsh", "-c", "while sleep 1000; do :; done"]
```

### Node.js Base Image Requirements

```dockerfile
FROM node:20-alpine

# Install essential development tools
RUN apk add --no-cache git zsh curl nano tree jq htop

# Install Oh My Zsh (optional but recommended)
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Set working directory
WORKDIR /app

# Keep container running
CMD ["zsh", "-c", "while sleep 1000; do :; done"]
```

### Image Compatibility

Your custom images should:
1. Include the base runtime (Python 3.11+ or Node.js 20+)
2. Include package managers (pip/uv for Python, npm for Node.js)
3. Have development tools if desired
4. Use `/workspace` (Python) or `/app` (Node.js) as working directory
5. Keep container running with a sleep command

## Fallback Behavior

When Docker Hub is unavailable or images are missing, Spinbox automatically falls back to local builds:

```bash
$ spinbox create myproject --fastapi --docker-hub
Warning: Could not reach Docker Hub, using local build instead...
Warning: This may take longer than usual
```

Common fallback scenarios:
- Network connectivity issues
- Docker Hub service outages  
- Missing or invalid image names
- Docker daemon not running

## Troubleshooting

### Image Not Found
```bash
Error: Image mycompany/custom-python-base not found on Docker Hub
→ Verify the image exists: docker pull mycompany/custom-python-base
→ Check your Docker Hub username and image names
```

### Network Issues
```bash
Warning: Could not reach Docker Hub
→ Check your internet connection
→ Verify Docker Hub is accessible: curl -s https://registry-1.docker.io/v2/
```

### Configuration Issues
```bash
Error: Invalid Docker Hub configuration
→ Check ~/.spinbox/global.conf syntax
→ Verify image names follow Docker naming conventions
```

### Docker Issues
```bash
Warning: Docker daemon not running
→ Start Docker Desktop or Docker service
→ Verify Docker is working: docker info
```

## Performance Benefits

Using Docker Hub can significantly speed up project creation:

| Scenario | Local Build | Docker Hub | Improvement |
|----------|-------------|------------|-------------|
| FastAPI project | 60-120s | 10-25s | 70-85% faster |
| Next.js project | 45-90s | 8-20s | 75-80% faster |
| Python project | 30-60s | 5-15s | 70-80% faster |

Performance varies based on:
- Network speed
- Docker Hub region
- Image size
- System specifications

## Security Considerations

When using custom Docker images:

1. **Trust**: Only use images from trusted sources
2. **Scanning**: Scan custom images for vulnerabilities
3. **Updates**: Keep base images updated with security patches
4. **Private registries**: Use private registries for sensitive projects
5. **Credentials**: Never include secrets in Docker images

## Configuration Reference

### Global Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DOCKER_HUB_USERNAME` | Docker Hub username | `gonzillaaa` |
| `DOCKER_HUB_REGISTRY` | Registry URL | `registry-1.docker.io/v2` |
| `SPINBOX_PYTHON_BASE_IMAGE` | Python base image | `gonzillaaa/spinbox-python-base` |
| `SPINBOX_NODE_BASE_IMAGE` | Node.js base image | `gonzillaaa/spinbox-node-base` |

### Configuration Hierarchy

Spinbox uses this configuration priority order:

1. **CLI flags** (highest priority)
2. **Global config file** (`~/.spinbox/global.conf`)  
3. **Default values** (lowest priority)

### Example Complete Configuration

```bash
# ~/.spinbox/global.conf

# Version preferences
PYTHON_VERSION="3.11"
NODE_VERSION="20"

# Docker Hub configuration
DOCKER_HUB_USERNAME="mycompany"
SPINBOX_PYTHON_BASE_IMAGE="mycompany/python-dev"
SPINBOX_NODE_BASE_IMAGE="mycompany/node-dev"

# Project defaults
PROJECT_AUTHOR="My Name"
PROJECT_EMAIL="me@company.com"
PROJECT_LICENSE="MIT"
```

## Related Documentation

- [CLI Reference](cli-reference.md) - Complete command reference
- [Project Profiles](profiles.md) - Pre-configured project types
- [Dependencies Management](dependency-management.md) - Managing project dependencies
- [Troubleshooting](troubleshooting.md) - Common issues and solutions

---

*Generated by Spinbox CLI - For more information, visit the [project repository](https://github.com/Gonzillaaa/spinbox)*