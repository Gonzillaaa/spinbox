# Spinbox CLI Reference

Complete command-line interface reference for Spinbox prototyping environment tool.

## Overview

Spinbox provides a comprehensive CLI for creating and managing containerized prototyping environments. This reference covers all commands, options, and usage patterns.

## Global Options

These options are available for all commands:

| Option | Short | Description |
|--------|-------|-------------|
| `--verbose` | `-v` | Enable verbose output |
| `--dry-run` | `-d` | Show what would be done without making changes |
| `--help` | `-h` | Show help message |
| `--version` | | Show version information |

## Commands

### `spinbox create`

Create a new development project with specified components or profiles.

#### Syntax
```bash
spinbox create <PROJECT_NAME> [OPTIONS]
```

#### Options

**Profile Selection:**
| Option | Description |
|--------|-------------|
| `--profile <name>` | Use predefined project profile |

**Component Selection:**
| Option | Description |
|--------|-------------|
| `--python` | Add Python DevContainer environment |
| `--node` | Add Node.js DevContainer environment |
| `--fastapi` | Add FastAPI backend component |
| `--nextjs` | Add Next.js frontend component |
| `--postgresql` | Add PostgreSQL database with PGVector |
| `--mongodb` | Add MongoDB document database |
| `--redis` | Add Redis for caching and queues |
| `--chroma` | Add Chroma vector database |

**Version Configuration:**
| Option | Description |
|--------|-------------|
| `--python-version <ver>` | Python version (default: 3.12) |
| `--node-version <ver>` | Node.js version (default: 20) |
| `--postgres-version <ver>` | PostgreSQL version (default: 15) |
| `--redis-version <ver>` | Redis version (default: 7) |

**Project Options:**
| Option | Description |
|--------|-------------|
| `--dir <path>` | Create project in specific directory |
| `--template <name>` | Use requirements.txt template |
| `--force` | `-f` | Overwrite existing directory |

#### Examples

**Profile-based creation:**
```bash
# Full-stack web application
spinbox create myapp --profile web-app

# FastAPI API with PostgreSQL and Redis
spinbox create api-server --profile api-only

# Data science environment
spinbox create ml-project --profile data-science

# AI/LLM prototyping environment
spinbox create ai-project --profile ai-llm

# Minimal prototyping environment
spinbox create basic-env --profile minimal
```

**Component-based creation:**
```bash
# Simple Python project
spinbox create myproject --python

# Custom full-stack setup
spinbox create webapp --python --node --postgresql --redis

# API layer with caching
spinbox create api --fastapi --redis

# Frontend with MongoDB
spinbox create frontend-app --nextjs --mongodb
```

**Version customization:**
```bash
# Override Python version
spinbox create legacy-api --fastapi --python-version 3.10

# Custom Node.js version
spinbox create old-frontend --nextjs --node-version 18

# Multiple version overrides
spinbox create custom-stack --profile web-app --python-version 3.11 --node-version 19
```

**Advanced options:**
```bash
# Create in specific directory
spinbox create myproject --python --dir /path/to/project

# Use specific requirements template
spinbox create data-proj --python --template data-science

# Force overwrite existing directory
spinbox create myproject --python --force
```

### `spinbox add`

Add components to an existing Spinbox project.

#### Syntax
```bash
spinbox add [OPTIONS]
```

#### Requirements
- Must be run from within a Spinbox project directory
- Project must have `.devcontainer/devcontainer.json` file

#### Options

**Component Addition:**
| Option | Description |
|--------|-------------|
| `--fastapi` | Add FastAPI backend component |
| `--nextjs` | Add Next.js frontend component |
| `--postgresql` | Add PostgreSQL database with PGVector |
| `--mongodb` | Add MongoDB document database |
| `--redis` | Add Redis for caching and queues |
| `--chroma` | Add Chroma vector database |

**Version Configuration:**
| Option | Description |
|--------|-------------|
| `--python-version <ver>` | Python version (uses current or default) |
| `--node-version <ver>` | Node.js version (uses current or default) |
| `--postgres-version <ver>` | PostgreSQL version (uses current or default) |
| `--redis-version <ver>` | Redis version (uses current or default) |

#### Examples

```bash
# Add PostgreSQL to existing project
cd myproject
spinbox add --postgresql

# Add multiple components with clear architectural roles
spinbox add --postgresql --redis        # Primary storage + caching layer
spinbox add --mongodb --chroma        # Alternative storage + vector search

# Add with version specification
spinbox add --postgresql --postgres-version 14

# Add Next.js to FastAPI-only project
spinbox add --nextjs --node-version 18
```

#### Behavior
- Detects existing components and only adds new ones
- Preserves existing configuration where possible
- Updates DevContainer and Docker Compose configurations
- Maintains project integrity

### `spinbox start`

Start project services using Docker Compose.

#### Syntax
```bash
spinbox start [OPTIONS]
```

#### Requirements
- Must be run from within a Spinbox project directory
- Project must have `docker-compose.yml` file

#### Options

| Option | Short | Description |
|--------|-------|-------------|
| `--detach` | `-d` | Run containers in background (default) |
| `--logs` | | Show service logs after starting |
| `--build` | | Build images before starting |
| `--force-recreate` | | Recreate containers even if config unchanged |

#### Examples

```bash
# Start all services in background
spinbox start

# Start and show logs
spinbox start --logs

# Rebuild and start
spinbox start --build

# Force recreate all containers
spinbox start --force-recreate

# Start in foreground (not detached)
spinbox start --no-detach
```

#### Behavior
- Starts all services defined in `docker-compose.yml`
- Services run in detached mode by default
- Provides status feedback and error handling
- Can show logs if requested

### `spinbox update`

Update Spinbox to the latest version or a specific version.

#### Syntax
```bash
spinbox update [OPTIONS]
```

#### Options
| Option | Description |
|--------|-------------|
| `--check` | Check for updates without installing |
| `--version VERSION` | Update to specific version (e.g., 1.2.0) |
| `--force` | Force update even if already on latest version |
| `--yes` | Skip confirmation prompts |
| `--dry-run` | Show what would be updated without making changes |
| `--verbose` | Enable verbose output |

#### Examples
```bash
# Check for updates
spinbox update --check

# Update to latest version
spinbox update

# Update to specific version
spinbox update --version 1.2.0

# Force update with no prompts
spinbox update --force --yes

# Preview update process
spinbox update --dry-run
```

#### Behavior
- **Automatic backup**: Creates backup of current installation before updating
- **Installation method detection**: Automatically detects if installed via Homebrew or manual installation
- **Homebrew integration**: Uses `brew upgrade spinbox` for Homebrew installations
- **Rollback support**: Automatically rolls back on failed updates
- **Configuration preservation**: Preserves user configuration during updates
- **Version validation**: Validates version numbers and checks availability
- **Network requirements**: Requires internet connection to check for updates

#### Update Process
1. **Check current version** and compare with target version
2. **Detect installation method** (Homebrew vs manual)
3. **Create backup** of current installation
4. **Download update** from GitHub releases
5. **Install update** atomically
6. **Verify installation** works correctly
7. **Clean up** temporary files
8. **Rollback** if any step fails

#### Notes
- Updates preserve user configuration files in `~/.spinbox/config/`
- Backup files are stored in `~/.spinbox/backup/`
- Failed updates are automatically rolled back
- Network connectivity is required for update checks
- Homebrew users should use `brew upgrade spinbox` directly when possible

### `spinbox uninstall`

Remove Spinbox from the system with optional configuration cleanup.

#### Syntax
```bash
spinbox uninstall [OPTIONS]
```

#### Options

| Option | Description |
|--------|-------------|
| `--config` | Also remove configuration files (~/.spinbox) |
| `--all` | Remove everything including config (same as --config) |
| `--script` | Download and run standalone uninstall script |
| `--force` | `-f` | Skip confirmation prompts |
| `--dry-run` | `-d` | Show what would be removed without making changes |

#### Examples

**Basic uninstall:**
```bash
# Remove Spinbox binary only (preserves configuration)
spinbox uninstall

# Remove binary and configuration files  
spinbox uninstall --config

# Remove everything
spinbox uninstall --all
```

**Advanced options:**
```bash
# Dry-run to see what would be removed
spinbox uninstall --dry-run --config

# Force removal without confirmation
spinbox uninstall --force --config

# Use standalone script (for corrupted installations)
spinbox uninstall --script
```

#### Behavior
- By default, only removes the Spinbox binary
- Configuration files preserved unless `--config` or `--all` specified
- Supports dry-run mode to preview changes
- Provides confirmation prompts unless `--force` used
- Detects Homebrew installations and suggests appropriate method
- Standalone script option for recovery scenarios

#### Notes
- Homebrew installations should use `brew uninstall spinbox`
- Projects created with Spinbox are not affected
- Docker images and containers remain untouched
- Use `--script` if the main binary is corrupted

### `spinbox config`

Manage global Spinbox configuration.

#### Syntax
```bash
spinbox config [OPTIONS]
```

#### Options

**Actions:**
| Option | Description |
|--------|-------------|
| `--list` | Show current configuration (default) |
| `--set <key>=<value>` | Set configuration value |
| `--get <key>` | Get specific configuration value |
| `--reset <scope>` | Reset configuration to defaults |
| `--setup` | Interactive configuration setup |

**Scope:**
| Option | Description |
|--------|-------------|
| `--global` | Operate on global configuration (default) |
| `--user` | Operate on user preferences |

#### Configuration Keys

**Global Configuration:**
| Key | Description | Default |
|-----|-------------|---------|
| `PYTHON_VERSION` | Default Python version | `3.12` |
| `NODE_VERSION` | Default Node.js version | `20` |
| `POSTGRES_VERSION` | Default PostgreSQL version | `15` |
| `REDIS_VERSION` | Default Redis version | `7` |
| `PROJECT_AUTHOR` | Default project author | `""` |
| `PROJECT_EMAIL` | Default project email | `""` |
| `PROJECT_LICENSE` | Default project license | `MIT` |
| `DEFAULT_COMPONENTS` | Default components to include | `""` |

**User Preferences:**
| Key | Description | Default |
|-----|-------------|---------|
| `PREFERRED_EDITOR` | Preferred code editor | `code` |
| `AUTO_START_SERVICES` | Auto-start services after creation | `true` |
| `SKIP_CONFIRMATIONS` | Skip confirmation prompts | `false` |

#### Examples

**View configuration:**
```bash
# Show all configuration
spinbox config
spinbox config --list

# Show specific value
spinbox config --get PYTHON_VERSION
```

**Set configuration:**
```bash
# Set default Python version
spinbox config --set PYTHON_VERSION=3.11

# Set project defaults
spinbox config --set PROJECT_AUTHOR="John Doe"
spinbox config --set PROJECT_EMAIL="john@example.com"

# Set user preferences
spinbox config --set PREFERRED_EDITOR=cursor --user
```

**Reset configuration:**
```bash
# Reset global configuration
spinbox config --reset global

# Reset user preferences
spinbox config --reset user
```

**Interactive setup:**
```bash
# Guided configuration setup
spinbox config --setup
```

### `spinbox status`

Show project and configuration status information.

#### Syntax
```bash
spinbox status [OPTIONS]
```

#### Options

| Option | Description |
|--------|-------------|
| `--project` | Show project-specific information |
| `--config` | Show configuration status |
| `--components` | Show available components |
| `--all` | Show all status information (default) |

#### Examples

```bash
# Show all status information
spinbox status

# Show only project status
spinbox status --project

# Show only configuration
spinbox status --config

# Show available components
spinbox status --components
```

#### Output Information

**Project Status:**
- Project detection (Spinbox project or not)
- Project name and description (if configured)
- Detected components (fastapi, nextjs, postgresql, etc.)
- DevContainer status

**Configuration Status:**
- Global configuration file status
- Current software versions
- User preferences status
- Configuration file locations

**Components Status:**
- List of all available components
- Component descriptions
- Usage examples

### `spinbox profiles`

List and display information about available project profiles.

#### Syntax
```bash
spinbox profiles [OPTIONS] [PROFILE_NAME]
```

#### Options

| Option | Description |
|--------|-------------|
| `--list` | List all available profiles (default) |
| `--show <profile>` | Show detailed information about specific profile |

#### Examples

```bash
# List all profiles
spinbox profiles
spinbox profiles --list

# Show specific profile details
spinbox profiles web-app
spinbox profiles --show api-only
```

#### Available Profiles

| Profile | Description | Components |
|---------|-------------|------------|
| `web-app` | Full-stack web application | fastapi, nextjs, postgresql |
| `api-only` | FastAPI API with PostgreSQL | fastapi, postgresql, redis |
| `data-science` | Data science environment | python, postgresql |
| `ai-llm` | AI/LLM development | python, postgresql, chroma |
| `minimal` | Basic prototyping environment | python |

#### Profile Details

Each profile shows:
- Description and use case
- Included components
- Default software versions
- Requirements template used
- Example usage commands

### `spinbox version`

Show version information.

#### Syntax
```bash
spinbox version
spinbox --version
```

#### Output
```
Spinbox v1.0.0
Prototyping Environment Scaffolding Tool

Copyright (c) 2024 Spinbox Contributors
Licensed under MIT License
```

### `spinbox help`

Show help information for commands.

#### Syntax
```bash
spinbox help [COMMAND]
spinbox --help
spinbox <COMMAND> --help
```

#### Examples

```bash
# General help
spinbox help
spinbox --help

# Command-specific help
spinbox help create
spinbox create --help

# All available help topics
spinbox help create
spinbox help add
spinbox help start
spinbox help config
spinbox help status
spinbox help profiles
```

## Configuration Files

### Global Configuration

**Location:** `~/.spinbox/config/global.conf`

**Format:**
```bash
# Software versions
PYTHON_VERSION="3.12"
NODE_VERSION="20"
POSTGRES_VERSION="15"
REDIS_VERSION="7"

# Project defaults
PROJECT_AUTHOR="Your Name"
PROJECT_EMAIL="your.email@example.com"
PROJECT_LICENSE="MIT"
DEFAULT_COMPONENTS=""
```

### User Preferences

**Location:** `~/.spinbox/config/user.conf`

**Format:**
```bash
# User preferences
PREFERRED_EDITOR="code"
AUTO_START_SERVICES="true"
SKIP_CONFIRMATIONS="false"
```

### Project Configuration

**Location:** `<project>/.config/project.conf`

**Format:**
```bash
# Project-specific configuration
PROJECT_NAME="myproject"
PROJECT_DESCRIPTION="My development project"
CREATED_DATE="2024-01-01"
SPINBOX_VERSION="1.0.0"
```

## Templates

### Requirements Templates

Available Python requirements templates:

| Template | Description | Key Libraries |
|----------|-------------|---------------|
| `minimal` | Basic prototyping tools | uv, pytest, black, requests |
| `data-science` | ML/data science libraries | pandas, numpy, matplotlib, jupyter |
| `ai-llm` | AI/LLM development | openai, anthropic, langchain, tiktoken |
| `web-scraping` | Web scraping tools | beautifulsoup4, selenium, scrapy |
| `api-development` | API development | fastapi, uvicorn, pydantic, httpx |
| `custom` | Minimal template for customization | Basic tools only |

### Profile Templates

Located at: `~/.spinbox/templates/profiles/`

**Format (TOML):**
```toml
[profile]
name = "web-app"
description = "Full-stack web application"

[components]
fastapi = true
nextjs = true
postgresql = true
redis = false
mongodb = false
chroma = false

[configuration]
python_version = "3.12"
node_version = "20"
postgres_version = "15"

[templates]
python_requirements = "api-development"
```

## Environment Variables

### Configuration Override

| Variable | Description | Example |
|----------|-------------|---------|
| `SPINBOX_CONFIG_DIR` | Override config directory | `/custom/path` |
| `SPINBOX_CACHE_DIR` | Override cache directory | `/custom/cache` |
| `SPINBOX_DEBUG` | Enable debug mode | `true` |

### Version Override

| Variable | Description | Example |
|----------|-------------|---------|
| `PYTHON_VERSION` | Override Python version | `3.11` |
| `NODE_VERSION` | Override Node.js version | `18` |
| `POSTGRES_VERSION` | Override PostgreSQL version | `14` |
| `REDIS_VERSION` | Override Redis version | `6` |

## Exit Codes

| Code | Description |
|------|-------------|
| `0` | Success |
| `1` | General error |
| `2` | Command not found |
| `3` | Invalid arguments |
| `4` | Configuration error |
| `5` | Project error |
| `6` | Docker error |

## Common Patterns

### Project Creation Workflow
```bash
# 1. Create project
spinbox create myproject --profile web-app

# 2. Navigate to project
cd myproject

# 3. Open in editor
code .

# 4. Start services
spinbox start
```

### Development Workflow
```bash
# Start development session
cd myproject
spinbox start --logs

# Add new components as needed
spinbox add --redis --chroma

# Check project status
spinbox status --project
```

### Configuration Management
```bash
# Set up global preferences
spinbox config --setup

# View current settings
spinbox config --list

# Adjust for specific needs
spinbox config --set PYTHON_VERSION=3.11
```

---

This CLI reference provides complete documentation for all Spinbox commands and options. For additional help, use `spinbox --help` or `spinbox <command> --help` for command-specific assistance.