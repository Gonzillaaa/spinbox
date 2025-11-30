# Troubleshooting Guide

Common issues and solutions when using Spinbox.

**Note**: Spinbox uses a DevContainer-first approach. Ensure you're working inside the DevContainer, not on the host system.

## CLI Errors

### Invalid Project Name
```
[-] Invalid project name: 'My Project'
```
Project names must: start with lowercase letter/number, contain only `a-z`, `0-9`, `-`, `_`, be ≤50 characters.

```bash
# Valid examples
spinbox create myproject --python
spinbox create my-app --profile web-app
```

### Directory Already Exists
```bash
# Use --force to overwrite
spinbox create myproject --force --python

# Or use different name
spinbox create myproject-v2 --python
```

### Permission Denied
```bash
# Create in home directory instead
spinbox create ~/myproject --python
```

### Unknown Option
```bash
# Check available options
spinbox create --help
```

## Docker Issues

### Docker Not Running
Start Docker Desktop and wait for it to fully initialize.

```bash
# Check status
docker ps

# macOS: Start Docker Desktop
open -a Docker
```

### Permission Denied (Linux)
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Disk Space Issues
```bash
# Clean up Docker resources
docker system prune -a
docker volume prune
```

## Container Issues

### Port Conflicts
```bash
# Find processes using ports
lsof -i :3000
lsof -i :8000
lsof -i :5432

# Kill process or change ports in docker-compose.yml
```

### Containers Won't Start
```bash
# Check logs
docker-compose logs [service-name]

# Check status
docker-compose ps

# Rebuild
docker-compose down
docker-compose up --build
```

### Slow Performance
- Increase Docker Desktop memory (minimum 4GB)
- Enable VirtioFS (macOS)
- Use `.dockerignore` to exclude `node_modules`, `.git`, etc.

## DevContainer Issues

### DevContainer Won't Open
1. Update VS Code/Cursor and Dev Containers extension
2. Rebuild: `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"
3. Check `devcontainer.json` syntax

### Extensions Not Installing
```bash
# Rebuild without cache
Ctrl+Shift+P → "Dev Containers: Rebuild Without Cache"
```

## Network Issues

### Update Check Failures
```bash
# Test connectivity
ping github.com
curl -I https://api.github.com
```

If GitHub API rate limited, wait 1 hour or try again later.

### Services Can't Communicate
Use service names (not `localhost`) in connection URLs:
```bash
DATABASE_URL=postgresql://postgres:postgres@database:5432/app_db
```

## Component Issues

### FastAPI
```bash
# Check Python version (should be 3.11+)
python --version

# Reinstall dependencies (inside DevContainer)
pip install -r requirements.txt
```

### Next.js
```bash
# Clear and reinstall
cd frontend
rm -rf node_modules package-lock.json
npm install
```

### PostgreSQL
```bash
# Check database
docker-compose exec database pg_isready -h localhost -U postgres

# Reset database
docker-compose down -v
docker-compose up database

# View logs
docker-compose logs database
```

### Redis
```bash
# Check Redis
docker-compose exec redis redis-cli ping
```

## Dependency Issues

### Dependencies Not Added
Ensure you used `--with-deps` flag:
```bash
spinbox create myproject --fastapi --with-deps
spinbox add --redis --with-deps
```

### Version Conflicts
```bash
# Check installed packages
pip list
npm list

# Remove duplicates from requirements.txt
pip freeze > requirements.txt
```

## Getting Help

```bash
# CLI help
spinbox --help
spinbox create --help

# Check project status
spinbox status
```

**Resources:**
- [GitHub Issues](https://github.com/Gonzillaaa/spinbox/issues)
- [CLI Reference](./cli-reference.md)
