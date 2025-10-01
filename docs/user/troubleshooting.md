# Troubleshooting Guide

This guide helps you resolve common issues when using Spinbox.

## Important Note

This project uses a **DevContainer-first approach**. All development is designed to happen inside DevContainers, where Python virtual environments and dependencies are automatically managed. If you're having issues, ensure you're working inside the DevContainer rather than on the host system.

## Table of Contents

- [Common Spinbox CLI Errors](#common-spinbox-cli-errors)
- [Docker Issues](#docker-issues)
- [Container Issues](#container-issues)
- [DevContainer Issues](#devcontainer-issues)
- [Dependency Management Issues](#dependency-management-issues)
- [Network Issues](#network-issues)
- [Performance Issues](#performance-issues)
- [Script Issues](#script-issues)
- [Component-Specific Issues](#component-specific-issues)
- [Getting Help](#getting-help)

## Common Spinbox CLI Errors

### Project Name Validation Errors

**Symptom:**
```
[-] Invalid project name: 'My Project'
```

**Cause:**
Project names must follow specific naming conventions for filesystem and Docker compatibility.

**Solution:**
Project names must:
- Start with a lowercase letter or number
- Contain only lowercase letters, numbers, hyphens (-) and underscores (_)
- Be 50 characters or less
- No spaces, special characters, or uppercase letters

**Valid Examples:**
```bash
spinbox create myproject --python
spinbox create my-app --profile web-app
spinbox create web_app_v2 --fastapi
```

### Project Name Too Long

**Symptom:**
```
[-] Project name too long: 'very-long-name...' (68 characters)
[i] Project names must be 50 characters or less
```

**Cause:**
Project names are limited to 50 characters for filesystem compatibility.

**Solution:**
Use a shorter, more concise name:
```bash
# Too long (68 chars)
spinbox create this-is-a-very-long-project-name-that-exceeds-fifty-characters-limit --python

# Better (shorter alternative)
spinbox create long-project-name --python
```

### Insufficient Disk Space

**Symptom:**
```
[-] Insufficient disk space
[i] Available: 5MB
[i] Required: 10MB (minimum)
```

**Cause:**
Less than 10MB of free disk space available.

**Solution:**
1. Free up disk space:
   ```bash
   # Check disk usage
   df -h

   # Clean up old projects
   rm -rf ~/old-projects

   # Clean Docker resources
   docker system prune -a
   ```

2. Create project on different volume with more space:
   ```bash
   spinbox create /Volumes/External/myproject --python
   ```

### Directory Already Exists

**Symptom:**
```
[-] Project directory already exists: ./myproject
```

**Cause:**
A directory with that name already exists in the target location.

**Solutions:**
1. Use `--force` to overwrite (deletes existing directory):
   ```bash
   spinbox create myproject --force --python
   ```

2. Choose a different name:
   ```bash
   spinbox create myproject-v2 --python
   ```

3. Create in a different location:
   ```bash
   spinbox create ~/projects/myproject --python
   ```

### Permission Denied

**Symptom:**
```
[-] Permission denied: Cannot create project in /some/directory
```

**Cause:**
Your user doesn't have write permissions for the target directory.

**Solutions:**
1. Create in your home directory:
   ```bash
   spinbox create ~/myproject --python
   ```

2. Create in current directory:
   ```bash
   spinbox create myproject --python
   ```

3. Check and fix permissions:
   ```bash
   ls -la /parent/directory
   chmod u+w /parent/directory  # If you own it
   ```

### Empty Project Name

**Symptom:**
```
[-] Project name cannot be empty
```

**Cause:**
No project name provided to the create command.

**Solution:**
Always provide a project name:
```bash
spinbox create <PROJECT_NAME> [OPTIONS]
spinbox create myproject --python
```

### Unknown Option Error

**Symptom:**
```
[-] Unknown option for create: --invalid
```

**Cause:**
Used an option that doesn't exist or typo in option name.

**Solution:**
1. Check available options:
   ```bash
   spinbox create --help
   ```

2. Common valid options:
   - `--python`, `--node`, `--fastapi`, `--nextjs`
   - `--postgresql`, `--mongodb`, `--redis`, `--chroma`
   - `--profile`, `--with-deps`, `--docker-hub`
   - `--force`, `--dry-run`, `--verbose`

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

### Slow Container Performance

**Symptoms:**
- Long startup times
- Slow file operations
- High CPU usage

**Solutions:**

1. **Optimize Docker Desktop settings:**
   - Increase memory allocation (minimum 4GB recommended)
   - Enable "Use gRPC FUSE for file sharing" (macOS)
   - Use VirtioFS for better performance

2. **Optimize volume mounts:**
   ```yaml
   # Use cached mounts for better performance
   volumes:
     - .:/workspace:cached
     - /workspace/node_modules  # Anonymous volume for node_modules
   ```

3. **Use .dockerignore files:**
   ```bash
   # .dockerignore
   node_modules
   .git
   .next
   __pycache__
   *.log
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

4. **Check Dockerfile syntax and commands**

## DevContainer Issues

DevContainers are the primary prototyping environment for this project. All Python virtual environments and dependencies are managed inside containers.

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

## Dependency Management Issues

The `--with-deps` flag automatically manages Python and Node.js dependencies. Here are common issues and solutions.

### Dependencies Not Added to requirements.txt

**Symptoms:**
- `requirements.txt` exists but is empty or missing expected packages
- Python packages not available after installation

**Solutions:**
1. **Verify you used the flag correctly:**
   ```bash
   spinbox create myproject --fastapi --with-deps
   # NOT: spinbox create myproject --fastapi --deps
   ```

2. **Check component combinations:**
   - Only specific components support automatic dependencies
   - See [dependency management guide](./dependency-management.md) for supported components

3. **Manual dependency addition:**
   ```bash
   # Add dependencies to existing project
   spinbox add --redis --with-deps
   ```

### Dependencies Not Added to package.json

**Symptoms:**
- `package.json` missing dependencies for Node.js components
- npm install fails or packages not found

**Solutions:**
1. **Verify Next.js component was added:**
   ```bash
   # Must include Node.js components for package.json generation
   spinbox create myproject --nextjs --with-deps
   ```

2. **Check project structure:**
   ```bash
   # Verify package.json exists in nextjs/ directory
   ls nextjs/package.json
   ```

3. **Reinstall with dependencies:**
   ```bash
   cd nextjs/
   npm install
   ```

### Dependency Conflicts

**Symptoms:**
- Installation errors about conflicting versions
- Some packages not installing correctly

**Solutions:**
1. **Check for duplicate additions:**
   ```bash
   # Avoid adding the same component multiple times
   spinbox status  # Check what's already added
   ```

2. **Review generated files:**
   ```bash
   # Check requirements.txt for duplicates
   cat requirements.txt | sort | uniq
   
   # Check package.json for conflicts
   cd nextjs/ && npm list
   ```

3. **Manual cleanup:**
   ```bash
   # Remove duplicates from requirements.txt
   pip freeze > requirements.txt
   ```

### Missing Component Dependencies

**Symptoms:**
- Expected packages not in requirements.txt/package.json
- Component-specific functionality not working

**Solutions:**
1. **Verify component support:**
   - Check [dependency management guide](./dependency-management.md)
   - Not all components have automatic dependencies

2. **Check TOML templates:**
   ```bash
   # Verify component is in dependency templates
   cat ~/.spinbox/templates/dependencies/python-components.toml
   ```

3. **Add dependencies manually:**
   ```bash
   # Add to requirements.txt
   echo "missing-package==1.0.0" >> requirements.txt
   
   # Add to package.json
   cd nextjs/ && npm install missing-package
   ```

### Setup Script Issues

**Symptoms:**
- `setup_deps.sh` missing or not executable
- Dependencies not installing in DevContainer

**Solutions:**
1. **Check script exists:**
   ```bash
   ls -la setup_deps.sh
   chmod +x setup_deps.sh
   ```

2. **Run script manually:**
   ```bash
   # Inside DevContainer
   ./setup_deps.sh
   ```

3. **Verify script contents:**
   ```bash
   # Check generated installation commands
   cat setup_deps.sh
   ```

For more detailed information about automatic dependency management, see the [Dependency Management Guide](./dependency-management.md).

## Network Issues

### Update Check Failures

**Symptoms:**
```
[-] Unable to check for updates
[i] → Check your internet connection
```

**Causes:**
- No internet connection
- DNS resolution failures
- GitHub API temporarily unavailable
- Firewall blocking requests

**Solutions:**

1. **Verify internet connection:**
   ```bash
   # Test basic connectivity
   ping -c 3 github.com

   # Test HTTPS access
   curl -I https://api.github.com
   ```

2. **Check firewall settings:**
   ```bash
   # Ensure curl/wget can access GitHub
   curl -v https://api.github.com/repos/Gonzillaaa/spinbox/releases
   ```

3. **GitHub API rate limiting:**
   ```
   [-] Failed to fetch release information (HTTP 403)
   [i] → GitHub API rate limit reached
   [i] → Try again later
   ```
   Wait 1 hour for rate limit to reset, or authenticate with GitHub token.

4. **Try again later:**
   If GitHub is temporarily unavailable, wait a few minutes and retry.

5. **Check current version without update:**
   ```bash
   spinbox --version
   ```

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

## Script Issues

### Script Permission Errors

**Symptoms:**
- Permission denied when running scripts
- Scripts won't execute

**Solutions:**

1. **Make scripts executable:**
   ```bash
   chmod +x *.sh
   chmod +x lib/*.sh
   ```

2. **Check script ownership:**
   ```bash
   ls -la *.sh
   chown $USER:$USER *.sh
   ```

### Script Fails with "Command not found"

**Symptoms:**
- Command not found errors
- Missing dependencies

**Solutions:**

1. **Install missing dependencies:**
   ```bash
   # Check what's missing
   which git docker docker-compose code
   
   # Install missing tools
   brew install git docker
   ```

2. **Update PATH:**
   ```bash
   echo $PATH
   export PATH="/usr/local/bin:$PATH"
   ```

3. **Source environment:**
   ```bash
   source ~/.zshrc
   ```

### Configuration Errors

**Symptoms:**
- Invalid configuration errors
- Scripts exit early

**Solutions:**

1. **Validate configuration:**
   ```bash
   # Use the built-in validation
   source lib/config.sh
   validate_config
   ```

2. **Reset configuration:**
   ```bash
   # Reset to defaults
   rm -rf ~/.spinbox/config/
   spinbox config --reset
   ```

3. **Check syntax:**
   ```bash
   # Check shell script syntax
   bash -n script-name.sh
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

## Getting Help

### Diagnostic Information

When seeking help, provide:

1. **System information:**
   ```bash
   # macOS
   sw_vers
   docker --version
   docker-compose --version
   code --version
   ```

2. **Error messages:**
   - Full error output
   - Container logs
   - Script execution logs

3. **Configuration files:**
   - docker-compose.yml
   - .devcontainer/devcontainer.json
   - Relevant Dockerfiles

### Log Collection

```bash
# Collect all logs
mkdir debug-info
docker-compose logs > debug-info/docker-logs.txt
ls -la > debug-info/file-listing.txt
cat .devcontainer/devcontainer.json > debug-info/devcontainer.json
cat docker-compose.yml > debug-info/docker-compose.yml
```

### Community Resources

1. **GitHub Issues:** Report bugs and request features
2. **Documentation:** Check official Docker and VS Code docs
3. **Forums:** Docker Community Forums, Stack Overflow
4. **Discord/Slack:** Development community channels

### Professional Support

For business-critical issues:
- Docker Business Support
- VS Code Enterprise Support
- Professional consulting services

For additional performance optimization tips, refer to your specific component documentation.