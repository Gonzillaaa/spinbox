# Troubleshooting Guide

This guide helps you resolve common issues when using Spinbox.

## Important Note

Spinbox uses a **DevContainer-first approach**. All development is designed to happen inside DevContainers, where Python virtual environments and dependencies are automatically managed. If you're having issues, ensure you're working inside the DevContainer rather than on the host system.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Docker Issues](#docker-issues)
- [Container Issues](#container-issues)
- [DevContainer Issues](#devcontainer-issues)
- [Network Issues](#network-issues)
- [Performance Issues](#performance-issues)
- [Component-Specific Issues](#component-specific-issues)
- [Getting Help](#getting-help)

## Installation Issues

### Spinbox Command Not Found

**Symptoms:**
- `spinbox: command not found`
- Shell can't find spinbox executable

**Solutions:**

1. **Check installation location:**
   ```bash
   # For user installations
   ls -la ~/.local/bin/spinbox
   
   # For system installations
   ls -la /usr/local/bin/spinbox
   ```

2. **Add to PATH (user installation):**
   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

3. **Add to PATH (system installation):**
   ```bash
   export PATH="/usr/local/bin:$PATH"
   echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

4. **Reinstall if needed:**
   ```bash
   # User installation (recommended)
   curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install-user.sh | bash
   
   # System installation
   curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh | sudo bash
   ```

### Permission Denied

**Symptoms:**
- Permission denied when running spinbox
- Cannot execute spinbox binary

**Solutions:**

1. **Make executable:**
   ```bash
   chmod +x ~/.local/bin/spinbox  # User installation
   chmod +x /usr/local/bin/spinbox  # System installation
   ```

2. **Check ownership:**
   ```bash
   ls -la ~/.local/bin/spinbox
   # Should be owned by your user
   ```

3. **Fix ownership if needed:**
   ```bash
   chown $USER:$USER ~/.local/bin/spinbox
   ```

## Docker Issues

### Docker Desktop Not Running

**Symptoms:**
- Error: "Cannot connect to the Docker daemon"
- Scripts fail with Docker-related errors

**Solutions:**
1. Start Docker Desktop application
2. Wait for Docker to fully initialize (look for green status indicator)
3. Check Docker Desktop preferences for sufficient resource allocation

**Prevention:**
- Set Docker Desktop to start automatically on system boot
- Allocate at least 4GB RAM and 2 CPU cores to Docker

### Docker Commands Not Found

**Symptoms:**
- Command not found: docker
- Command not found: docker-compose

**Solutions:**
1. **Install Docker Desktop:**
   ```bash
   # macOS with Homebrew
   brew install --cask docker
   
   # Or download from https://docker.com/products/docker-desktop
   ```

2. **Add Docker to PATH:**
   ```bash
   echo 'export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   ```

### Permission Issues

**Symptoms:**
- Permission denied when running Docker commands
- Cannot access Docker socket

**Solutions:**
1. **Add user to docker group (Linux):**
   ```bash
   sudo usermod -aG docker $USER
   newgrp docker
   ```

2. **Restart Docker Desktop**

3. **Check Docker socket permissions:**
   ```bash
   ls -la /var/run/docker.sock
   ```

### Disk Space Issues

**Symptoms:**
- "No space left on device" errors
- Failed to build images

**Solutions:**
1. **Clean up Docker resources:**
   ```bash
   # Remove unused containers, networks, images
   docker system prune -a
   
   # Remove specific volumes
   docker volume prune
   ```

2. **Check disk usage:**
   ```bash
   docker system df
   ```

3. **Increase Docker Desktop disk allocation**

## Container Issues

### Containers Won't Start

**Symptoms:**
- Services exit immediately
- Health checks fail
- Port binding errors

**Diagnostic Steps:**
1. **Check container logs:**
   ```bash
   docker-compose logs [service-name]
   ```

2. **Check container status:**
   ```bash
   docker-compose ps
   ```

3. **Inspect container configuration:**
   ```bash
   docker inspect [container-name]
   ```

**Common Solutions:**

1. **Port conflicts:**
   ```bash
   # Find processes using ports
   lsof -i :3000
   lsof -i :8000
   lsof -i :5432
   
   # Kill conflicting processes or change ports in docker-compose.yml
   ```

2. **Environment variable issues:**
   - Check `.env` file exists and has correct values
   - Verify environment variables in docker-compose.yml
   - Ensure no spaces around `=` in environment variables

3. **Volume mount issues:**
   ```bash
   # Check volume permissions
   ls -la /path/to/volume
   
   # Fix permissions if needed
   chmod -R 755 /path/to/volume
   ```

### Build Failures

**Symptoms:**
- Docker build commands fail
- Package installation errors
- Network timeouts during build

**Solutions:**

1. **Clear build cache:**
   ```bash
   docker-compose build --no-cache
   ```

2. **Check network connectivity:**
   ```bash
   # Test network from container
   docker run --rm alpine ping -c 3 google.com
   ```

3. **Update base images:**
   ```bash
   docker-compose pull
   docker-compose build
   ```

## DevContainer Issues

DevContainers are the primary prototyping environment for Spinbox. All Python virtual environments and dependencies are managed inside containers.

### DevContainer Won't Open

**Symptoms:**
- "Failed to start DevContainer" error
- Editor hangs when opening container
- Container fails to build

**Solutions:**

1. **Update editor and extensions:**
   - Update VS Code/Cursor to latest version
   - Update "Dev Containers" extension (VS Code) or ensure Cursor has latest DevContainer support

2. **Rebuild container:**
   ```
   VS Code: Ctrl+Shift+P → Dev Containers: Rebuild Container
   Cursor: Ctrl+Shift+P → Dev Containers: Rebuild Container
   ```

3. **Check devcontainer.json syntax:**
   - Validate JSON format
   - Check file paths are correct
   - Verify dockerComposeFile path

4. **Clear editor cache:**
   ```bash
   # For VS Code - close editor and remove cache
   rm -rf ~/.vscode/extensions/ms-vscode-remote.remote-containers-*
   
   # For Cursor - clear DevContainer cache
   # Cursor: Help → Reset Extension Host
   ```

### Extensions Not Installing

**Symptoms:**
- Editor extensions missing in container
- Extension installation fails

**Solutions:**

1. **Check extension IDs in devcontainer.json:**
   ```json
   "extensions": [
     "ms-python.python",
     "ms-python.vscode-pylance"
   ]
   ```

2. **Install extensions manually:**
   ```
   Ctrl+Shift+P → Extensions: Install from VSIX
   ```

3. **Rebuild container with clean cache:**
   ```
   VS Code: Ctrl+Shift+P → Dev Containers: Rebuild Without Cache
   Cursor: Ctrl+Shift+P → Dev Containers: Rebuild Without Cache
   ```

### Terminal Issues

**Symptoms:**
- Terminal doesn't open
- Wrong shell being used
- Font rendering issues

**Solutions:**

1. **Check terminal configuration:**
   ```json
   "terminal.integrated.defaultProfile.linux": "zsh",
   "terminal.integrated.fontFamily": "MesloLGS NF"
   ```

2. **Install required fonts:**
   ```bash
   # Install MesloLGS NF font on host system
   brew tap homebrew/cask-fonts
   brew install --cask font-meslo-lg-nerd-font
   ```

3. **Reset terminal:**
   ```
   Ctrl+Shift+P → Terminal: Kill All Terminals
   ```

## Network Issues

### Service Discovery Problems

**Symptoms:**
- Services can't communicate
- Connection refused errors
- DNS resolution failures

**Solutions:**

1. **Check network configuration:**
   ```bash
   docker network ls
   docker network inspect [network-name]
   ```

2. **Use service names in URLs:**
   ```bash
   # Use service name, not localhost
   DATABASE_URL=postgresql://postgres:postgres@database:5432/app_db
   ```

3. **Verify services are on same network:**
   ```yaml
   services:
     backend:
       networks:
         - app-network
     database:
       networks:
         - app-network
   
   networks:
     app-network:
       driver: bridge
   ```

### Port Forwarding Issues

**Symptoms:**
- Can't access services from host
- Ports not accessible in browser

**Solutions:**

1. **Check port mappings:**
   ```yaml
   services:
     backend:
       ports:
         - "8000:8000"  # host:container
   ```

2. **Verify ports in DevContainer:**
   ```json
   "forwardPorts": [3000, 8000, 5432, 6379]
   ```

3. **Check firewall settings:**
   ```bash
   # macOS
   sudo pfctl -sr | grep 8000
   
   # Check if ports are listening
   netstat -an | grep LISTEN
   ```

## Performance Issues

### Slow File Operations

**Symptoms:**
- Slow file saves
- Long build times
- High disk I/O

**Solutions:**

1. **Optimize volume mounts:**
   ```yaml
   volumes:
     - .:/workspace:cached
     - /workspace/node_modules
   ```

2. **Use .dockerignore:**
   ```
   node_modules
   .git
   .next
   build
   dist
   __pycache__
   ```

3. **Enable Docker Desktop performance features:**
   - Use VirtioFS (macOS)
   - Ensure proper resource allocation

### High Memory Usage

**Symptoms:**
- System slowdown
- Out of memory errors
- Container restarts

**Solutions:**

1. **Increase Docker memory limit:**
   - Docker Desktop → Preferences → Resources → Memory

2. **Optimize container memory usage:**
   ```yaml
   services:
     backend:
       deploy:
         resources:
           limits:
             memory: 512M
   ```

3. **Monitor memory usage:**
   ```bash
   docker stats
   ```

## Component-Specific Issues

### Backend (FastAPI) Issues

**Symptoms:**
- Import errors
- Package installation failures
- Server won't start

**Solutions:**

1. **Check Python version:**
   ```bash
   python --version  # Should be 3.12+
   ```

2. **Reinstall dependencies (in DevContainer):**
   ```bash
   # Rebuild DevContainer to reset environment
   # In VS Code: Ctrl+Shift+P → "Dev Containers: Rebuild Container"
   # Or manually inside container:
   cd /workspace
   rm -rf venv
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

3. **Check FastAPI application (in DevContainer):**
   ```bash
   # Inside DevContainer terminal
   cd backend
   uvicorn app.main:app --reload
   ```

### Frontend (Next.js) Issues

**Symptoms:**
- NPM/Yarn errors
- Build failures
- Port conflicts

**Solutions:**

1. **Clear npm cache:**
   ```bash
   cd frontend
   rm -rf node_modules package-lock.json
   npm install
   ```

2. **Check Node.js version:**
   ```bash
   node --version  # Should be 18+
   npm --version
   ```

3. **Fix port conflicts:**
   ```bash
   # Change port in package.json
   "dev": "next dev -p 3001"
   ```

### Database (PostgreSQL) Issues

**Symptoms:**
- Connection refused
- Authentication failures
- PGVector extension errors

**Solutions:**

1. **Check database status:**
   ```bash
   docker-compose exec database pg_isready -h localhost -U postgres
   ```

2. **Reset database:**
   ```bash
   docker-compose down -v
   docker-compose up database
   ```

3. **Check logs:**
   ```bash
   docker-compose logs database
   ```

4. **Connect manually:**
   ```bash
   docker-compose exec database psql -U postgres -d app_db
   ```

### Redis Issues

**Symptoms:**
- Connection timeouts
- Redis not responding
- Data persistence issues

**Solutions:**

1. **Check Redis status:**
   ```bash
   docker-compose exec redis redis-cli ping
   ```

2. **Check configuration:**
   ```bash
   docker-compose exec redis cat /usr/local/etc/redis/redis.conf
   ```

3. **Clear Redis data:**
   ```bash
   docker-compose exec redis redis-cli FLUSHALL
   ```

## Configuration Issues

### Spinbox Configuration Problems

**Symptoms:**
- Invalid configuration errors
- Commands fail with config errors
- Settings not being applied

**Solutions:**

1. **Check current configuration:**
   ```bash
   spinbox config --list
   ```

2. **Validate configuration files:**
   ```bash
   # Check if config files exist
   ls -la ~/.spinbox/config/
   
   # Check syntax
   cat ~/.spinbox/config/global.conf
   ```

3. **Reset configuration:**
   ```bash
   # Reset to defaults
   spinbox config --reset global
   spinbox config --setup
   ```

4. **Manual configuration cleanup:**
   ```bash
   # Remove config directory and recreate
   rm -rf ~/.spinbox/config/
   spinbox config --setup
   ```

## Enhancement Features Issues

### Dependency Management (`--with-deps`) Issues

**Symptoms:**
- Dependencies not added to requirements.txt/package.json
- Wrong dependencies added
- Cross-language contamination

**Solutions:**

1. **Verify flag usage:**
   ```bash
   # Ensure --with-deps flag is used
   spinbox create myproject --fastapi --postgresql --with-deps
   ```

2. **Check component detection:**
   ```bash
   # Verify components are detected correctly
   spinbox status --project
   ```

3. **Manual dependency addition:**
   ```bash
   # Add dependencies to existing project
   spinbox add --redis --with-deps
   ```

### Working Examples (`--with-examples`) Issues

**Symptoms:**
- Examples not copied to project
- Broken example code
- Missing documentation

**Solutions:**

1. **Verify flag usage:**
   ```bash
   # Ensure --with-examples flag is used
   spinbox create myproject --fastapi --postgresql --with-examples
   ```

2. **Check example files:**
   ```bash
   # Verify examples were copied
   ls -la */examples/ */README.md
   ```

3. **Add examples to existing project:**
   ```bash
   # Add examples to existing project
   spinbox add --redis --with-examples
   ```

## Getting Help

### Diagnostic Information

When seeking help, provide:

1. **System information:**
   ```bash
   # macOS
   sw_vers
   spinbox --version
   docker --version
   docker-compose --version
   code --version
   ```

2. **Error messages:**
   - Full error output
   - Container logs
   - Command execution logs

3. **Configuration files:**
   - docker-compose.yml
   - .devcontainer/devcontainer.json
   - Relevant configuration files

### Log Collection

```bash
# Collect all logs
mkdir debug-info
docker-compose logs > debug-info/docker-logs.txt
ls -la > debug-info/file-listing.txt
cat .devcontainer/devcontainer.json > debug-info/devcontainer.json
cat docker-compose.yml > debug-info/docker-compose.yml
spinbox config --list > debug-info/spinbox-config.txt
```

### Installation Verification

**Complete verification script:**
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

### Community Resources

1. **GitHub Issues:** Report bugs and request features
2. **Documentation:** Check the complete documentation in docs/user-guide/
3. **CLI Help:** Use `spinbox --help` and `spinbox <command> --help`

### Quick Commands for Common Issues

```bash
# Reset everything
spinbox config --reset global
docker system prune -a

# Check installation
which spinbox
spinbox --version

# Check Docker
docker --version
docker ps

# Check project status
spinbox status --project

# Rebuild DevContainer
# VS Code: Ctrl+Shift+P → Dev Containers: Rebuild Container
```

Remember to check the other documentation files for more specific guidance:
- [Installation Guide](./installation.md)
- [Quick Start Guide](./quick-start.md)
- [CLI Reference](./cli-reference.md)
- [Dependency Management](./dependency-management.md)
- [Working Examples](./working-examples.md)
