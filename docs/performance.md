# Performance Optimization Guide

This guide provides strategies to optimize the performance of your development environment created with the project template.

## Table of Contents

- [Docker Performance](#docker-performance)
- [Container Optimization](#container-optimization)
- [Volume Mount Performance](#volume-mount-performance)
- [Build Performance](#build-performance)
- [VS Code DevContainer Performance](#vs-code-devcontainer-performance)
- [Component-Specific Optimizations](#component-specific-optimizations)
- [Monitoring and Profiling](#monitoring-and-profiling)
- [Platform-Specific Optimizations](#platform-specific-optimizations)

## Docker Performance

### Resource Allocation

Proper resource allocation is crucial for optimal performance:

```bash
# Recommended minimum settings:
# - Memory: 8GB (4GB minimum)
# - CPU: 4 cores (2 minimum)
# - Disk: 100GB (60GB minimum)
```

#### Docker Desktop Settings

1. **Memory Allocation:**
   - Docker Desktop → Preferences → Resources → Memory
   - Allocate 60-80% of system RAM
   - Leave at least 2GB for host OS

2. **CPU Allocation:**
   - Use all available cores for development
   - Reduce for production-like testing

3. **Disk Space:**
   - Allocate generous disk space
   - Enable "Use gRPC FUSE for file sharing" (macOS)
   - Use VirtioFS for better I/O performance

### Storage Driver Optimization

```bash
# Check current storage driver
docker info | grep "Storage Driver"

# For better performance, use overlay2 (usually default)
```

### Network Performance

```yaml
# docker-compose.yml
version: '3.8'

networks:
  app-network:
    driver: bridge
    driver_opts:
      com.docker.network.driver.mtu: 1500
```

## Container Optimization

### Multi-Stage Builds

Optimize Dockerfiles with multi-stage builds:

```dockerfile
# backend/Dockerfile (optimized)
FROM python:3.12-slim as builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim as runtime
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
WORKDIR /app
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Layer Caching

Optimize layer caching by ordering commands strategically:

```dockerfile
# Good: Dependencies first (cached layer)
COPY requirements.txt .
RUN pip install -r requirements.txt

# Then application code (changes frequently)
COPY . .
```

### Minimize Image Size

```dockerfile
# Use slim/alpine variants
FROM python:3.12-slim

# Clean up in the same layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential && \
    pip install --no-cache-dir -r requirements.txt && \
    apt-get purge -y build-essential && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*
```

### Resource Limits

```yaml
# docker-compose.yml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
        reservations:
          memory: 512M
          cpus: '0.25'
```

## Volume Mount Performance

### Use Cached Mounts

```yaml
# docker-compose.yml
services:
  backend:
    volumes:
      - .:/workspace:cached  # Cached for better performance
      - backend-cache:/workspace/.cache  # Named volume for cache
```

### Anonymous Volumes for Dependencies

```yaml
services:
  frontend:
    volumes:
      - ./frontend:/app:cached
      - /app/node_modules  # Anonymous volume for node_modules
      - /app/.next  # Anonymous volume for Next.js cache
```

### Exclude Large Directories

Use `.dockerignore` to exclude unnecessary files:

```
# .dockerignore
node_modules
.next
.git
.cache
__pycache__
*.log
.DS_Store
Thumbs.db
.env.local
coverage/
.nyc_output
```

### Platform-Specific Volume Optimizations

#### macOS

```yaml
# Use delegated or cached consistency
volumes:
  - .:/workspace:delegated  # Host writes are prioritized
  - .:/workspace:cached     # Container reads are prioritized
```

#### Windows with WSL2

```yaml
# Store project files in WSL2 filesystem for better performance
# Clone project to: /home/username/projects/
```

## Build Performance

### Parallel Builds

```bash
# Build services in parallel
docker-compose build --parallel

# Use BuildKit for faster builds
export DOCKER_BUILDKIT=1
docker-compose build
```

### Build Context Optimization

```dockerfile
# Copy only necessary files first
COPY package*.json ./
RUN npm ci --only=production

# Copy source code last
COPY src/ ./src/
```

### Cache Mounts (BuildKit)

```dockerfile
# Use cache mounts for package managers
# syntax=docker/dockerfile:1
FROM node:18-alpine

RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production
```

### Registry Mirrors

```json
// ~/.docker/daemon.json
{
  "registry-mirrors": [
    "https://mirror.gcr.io"
  ]
}
```

## VS Code DevContainer Performance

### Extension Optimization

```json
// .devcontainer/devcontainer.json
{
  "extensions": [
    // Only include essential extensions
    "ms-python.python",
    "ms-python.vscode-pylance"
  ],
  "settings": {
    // Disable expensive features
    "python.linting.pylintEnabled": false,
    "python.linting.flake8Enabled": true,
    "files.watcherExclude": {
      "**/node_modules/**": true,
      "**/.git/**": true,
      "**/build/**": true
    }
  }
}
```

### Workspace Optimization

```json
{
  "settings": {
    // Reduce file watching
    "files.watcherExclude": {
      "**/node_modules/**": true,
      "**/.git/**": true,
      "**/dist/**": true,
      "**/build/**": true,
      "**/.cache/**": true
    },
    // Optimize search
    "search.exclude": {
      "**/node_modules": true,
      "**/bower_components": true,
      "**/coverage": true,
      "**/dist": true,
      "**/build": true
    }
  }
}
```

### Remote Development Performance

```json
{
  "remoteUser": "root",
  "workspaceFolder": "/workspace",
  "mounts": [
    // Mount only necessary directories
    "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached"
  ]
}
```

## Component-Specific Optimizations

### Backend (FastAPI) Performance

#### Dependency Installation

```bash
# Use UV for faster package installation
pip install uv
uv pip install -r requirements.txt
```

#### Runtime Optimization

```python
# app/main.py
from fastapi import FastAPI
import uvloop
import asyncio

# Use uvloop for better async performance
asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())

app = FastAPI()
```

#### Database Connection Pooling

```python
# Optimize SQLAlchemy connection pool
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=20,
    max_overflow=0,
    pool_pre_ping=True
)
```

### Frontend (Next.js) Performance

#### Build Optimization

```javascript
// next.config.js
const nextConfig = {
  experimental: {
    // Enable SWC minification for faster builds
    swcMinify: true,
  },
  // Optimize bundle analysis
  webpack: (config, { isServer }) => {
    if (!isServer) {
      config.resolve.fallback.fs = false;
    }
    return config;
  },
};

module.exports = nextConfig;
```

#### Development Server

```json
{
  "scripts": {
    "dev": "next dev --turbo",  // Use Turbopack for faster development
    "build": "next build",
    "start": "next start"
  }
}
```

### Database Performance

#### PostgreSQL Configuration

```sql
-- Custom postgresql.conf settings for development
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB
```

#### Connection Pooling

```yaml
# docker-compose.yml
services:
  database:
    environment:
      - POSTGRES_INITDB_ARGS=--auth-host=md5
    command: >
      postgres
      -c shared_buffers=256MB
      -c effective_cache_size=1GB
      -c work_mem=4MB
```

### Redis Performance

```
# redis/redis.conf
# Memory optimization
maxmemory 512mb
maxmemory-policy allkeys-lru

# Persistence optimization for development
save 900 1
save 300 10
save 60 10000

# Network optimization
tcp-keepalive 300
timeout 0
```

## Monitoring and Profiling

### Container Resource Monitoring

```bash
# Monitor container resource usage
docker stats

# Detailed container information
docker inspect [container-name]

# Monitor specific service
docker-compose exec backend top
```

### Performance Profiling

```bash
# Profile container startup time
time docker-compose up -d

# Profile build time
time docker-compose build

# Monitor disk usage
docker system df
docker system df -v
```

### Application Performance

#### Backend Profiling

```python
# Add to FastAPI app for profiling
import cProfile
import pstats
from fastapi import Request
import time

@app.middleware("http")
async def profile_request(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response
```

#### Frontend Performance

```javascript
// Add to Next.js for bundle analysis
const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
});

module.exports = withBundleAnalyzer(nextConfig);
```

### Log Analysis

```bash
# Analyze container logs for performance issues
docker-compose logs --follow --tail=100

# Filter logs by service
docker-compose logs backend | grep "ERROR\|WARN"
```

## Platform-Specific Optimizations

### macOS

1. **Enable VirtioFS:**
   - Docker Desktop → Preferences → Experimental Features
   - Enable "Use the new Virtualization framework"
   - Enable "VirtioFS accelerated directory sharing"

2. **Optimize File Sharing:**
   ```bash
   # Exclude unnecessary directories from file sharing
   # Docker Desktop → Preferences → Resources → File Sharing
   ```

3. **Use Rosetta 2 (Apple Silicon):**
   ```yaml
   # For x86 compatibility when needed
   services:
     backend:
       platform: linux/amd64
   ```

### Windows

1. **Use WSL2 Backend:**
   - Docker Desktop → Settings → General
   - Use WSL2 based engine

2. **Store Projects in WSL2:**
   ```bash
   # Clone projects to WSL2 filesystem
   cd /home/username/
   git clone [repository]
   ```

3. **Resource Allocation:**
   ```powershell
   # .wslconfig in %USERPROFILE%
   [wsl2]
   memory=8GB
   processors=4
   ```

### Linux

1. **Use cgroups v2:**
   ```bash
   # Check cgroups version
   cat /proc/filesystems | grep cgroup
   
   # Enable cgroups v2 if not enabled
   # Add to GRUB_CMDLINE_LINUX: systemd.unified_cgroup_hierarchy=1
   ```

2. **Optimize I/O Scheduler:**
   ```bash
   # For SSDs, use mq-deadline or none
   echo mq-deadline | sudo tee /sys/block/sda/queue/scheduler
   ```

## Performance Testing

### Automated Performance Tests

```bash
#!/bin/bash
# performance-test.sh

echo "Testing container startup time..."
time docker-compose up -d

echo "Testing application response time..."
curl -w "@curl-format.txt" -o /dev/null -s "http://localhost:8000/"

echo "Testing build time..."
time docker-compose build --no-cache
```

### Continuous Performance Monitoring

```yaml
# .github/workflows/performance.yml
name: Performance Test
on: [push, pull_request]

jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build and test performance
        run: |
          time docker-compose build
          time docker-compose up -d
          sleep 30
          curl -f http://localhost:8000/
```

## Best Practices Summary

1. **Resource Management:**
   - Allocate sufficient resources to Docker
   - Monitor resource usage regularly
   - Set appropriate resource limits

2. **Volume Optimization:**
   - Use cached/delegated consistency
   - Exclude unnecessary files
   - Use anonymous volumes for dependencies

3. **Build Optimization:**
   - Use multi-stage builds
   - Optimize layer caching
   - Use .dockerignore effectively

4. **Code Optimization:**
   - Enable compiler optimizations
   - Use efficient dependencies
   - Implement proper caching

5. **Monitoring:**
   - Regular performance testing
   - Resource usage monitoring
   - Application profiling

Remember that performance optimization is an iterative process. Start with the most impactful changes and measure the results before proceeding to more complex optimizations.