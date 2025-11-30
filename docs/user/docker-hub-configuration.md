# Docker Hub Configuration

Use pre-built Docker images for 50-70% faster project creation.

## Quick Start

```bash
spinbox create myproject --fastapi --docker-hub
spinbox create myapp --nextjs --docker-hub
```

## Default Images

| Type | Image | Size |
|------|-------|------|
| Python | `gonzillaaa/spinbox-python-base:latest` | 495MB |
| Node.js | `gonzillaaa/spinbox-node-base:latest` | 276MB |

Images include: git, zsh, oh-my-zsh, development tools, package managers.

## Custom Configuration

Edit `~/.spinbox/global.conf`:

```bash
DOCKER_HUB_USERNAME="mycompany"
SPINBOX_PYTHON_BASE_IMAGE="mycompany/python-dev"
SPINBOX_NODE_BASE_IMAGE="mycompany/node-dev"
```

## Creating Custom Images

### Python Base Requirements
```dockerfile
FROM python:3.11-slim
RUN apt-get update && apt-get install -y git curl zsh
RUN pip install --no-cache-dir uv
WORKDIR /workspace
CMD ["zsh", "-c", "while sleep 1000; do :; done"]
```

### Node.js Base Requirements
```dockerfile
FROM node:20-alpine
RUN apk add --no-cache git zsh curl
WORKDIR /app
CMD ["zsh", "-c", "while sleep 1000; do :; done"]
```

## Fallback Behavior

If Docker Hub is unavailable, Spinbox builds locally:
```
Warning: Could not reach Docker Hub, using local build instead...
```

## Performance

| Scenario | Local Build | Docker Hub |
|----------|-------------|------------|
| FastAPI | 60-120s | 10-25s |
| Next.js | 45-90s | 8-20s |
| Python | 30-60s | 5-15s |

## Configuration Reference

| Variable | Default |
|----------|---------|
| `DOCKER_HUB_USERNAME` | `gonzillaaa` |
| `SPINBOX_PYTHON_BASE_IMAGE` | `gonzillaaa/spinbox-python-base` |
| `SPINBOX_NODE_BASE_IMAGE` | `gonzillaaa/spinbox-node-base` |

Priority: CLI flags > `~/.spinbox/global.conf` > defaults
