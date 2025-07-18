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
spinbox create <PROJECT_PATH> [OPTIONS]
```

The `PROJECT_PATH` can be either:
- A simple project name: `myproject` (creates `./myproject/`)
- A relative path: `code/myproject` (creates `./code/myproject/`)
- An absolute path: `/path/to/myproject` (creates `/path/to/myproject/`)
- A home directory path: `~/projects/myproject` (creates `~/projects/myproject/`)

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

**Enhancement Flags:**
| Option | Description |
|--------|-------------|
| `--with-deps` | Automatically manage dependencies (add to requirements.txt/package.json) |
| `--with-examples` | Include working code examples for each component |

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

# Python prototyping environment
spinbox create basic-env --profile python
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

**Enhancement flags:**
```bash
# Create with automatic dependency management
spinbox create myproject --fastapi --postgresql --with-deps

# Create with working examples
spinbox create myproject --fastapi --postgresql --with-examples

# Create with both dependencies and examples
spinbox create myproject --fastapi --postgresql --with-deps --with-examples
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

**Enhancement Flags:**
| Option | Description |
|--------|-------------|
| `--with-deps` | Automatically manage dependencies for added components |
| `--with-examples` | Include working code examples for added components |

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

# Add with dependencies and examples
spinbox add --redis --with-deps --with-examples

# Add with version specification
spinbox add --postgresql --postgres-version 14

# Add Next.js to FastAPI-only project
spinbox add --nextjs --node-version 18
```

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
|-----|-------------|---------|----|
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
|-----|-------------|---------|----|
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
| `python` | Python development with essential tools | python + testing tools |
| `node` | Node.js development with TypeScript | node + typescript + testing |
| `web-app` | Full-stack web application | fastapi, nextjs, postgresql |
| `api-only` | FastAPI API with PostgreSQL | fastapi, postgresql, redis |
| `data-science` | Data science with pandas, numpy, matplotlib, Jupyter, scikit-learn, plotly | python, postgresql |
| `ai-llm` | AI/LLM with OpenAI, Anthropic, LangChain, Transformers, Chroma | python, postgresql, chroma |

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

```bash
# Remove Spinbox binary only (preserves configuration)
spinbox uninstall

# Remove binary and configuration files  
spinbox uninstall --config

# Remove everything
spinbox uninstall --all

# Dry-run to see what would be removed
spinbox uninstall --dry-run --config

# Force removal without confirmation
spinbox uninstall --force --config
```

### `spinbox version`

Show version information.

#### Syntax
```bash
spinbox version
spinbox --version
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

## Enhancement Flags

### Automatic Dependency Management (`--with-deps`)

Automatically adds dependencies to appropriate package files:

- **Python projects**: Adds packages to `requirements.txt`
- **Node.js projects**: Adds packages to `package.json`
- **Installation scripts**: Creates `setup-python-deps.sh` and `setup-nodejs-deps.sh`
- **Smart detection**: Prevents cross-contamination between Python and Node.js

**Example:**
```bash
spinbox create myproject --fastapi --postgresql --with-deps
# Results in requirements.txt with FastAPI, SQLAlchemy, PostgreSQL adapter, etc.
```

### Working Examples (`--with-examples`)

Includes production-ready code examples for each component:

- **Core components**: FastAPI, Next.js, PostgreSQL, Redis, MongoDB, Chroma
- **AI/LLM integration**: OpenAI, Anthropic, LangChain, LlamaIndex
- **Component combinations**: FastAPI + PostgreSQL, Next.js + FastAPI, etc.
- **Complete documentation**: Setup instructions, usage examples, best practices

**Example:**
```bash
spinbox create myproject --fastapi --postgresql --with-examples
# Results in working CRUD examples, authentication examples, etc.
```

### Combining Enhancement Flags

```bash
# Create complete development environment
spinbox create fullstack --fastapi --nextjs --postgresql --with-deps --with-examples

# Add component with both enhancements
spinbox add --redis --with-deps --with-examples
```

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
