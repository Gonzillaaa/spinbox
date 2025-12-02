# Spinbox Architecture

Technical architecture and design decisions for the Spinbox CLI.

## Overview

Spinbox is a shell-based CLI tool for creating containerized development environments. It generates DevContainer configurations, Docker Compose files, and project scaffolding.

**Core Philosophy**: Always choose the simplest possible implementation that works.

## Directory Structure

```
spinbox/
├── bin/
│   └── spinbox                 # Main CLI entry point
├── lib/
│   ├── utils.sh                # Shared utilities, error handling
│   ├── config.sh               # Configuration management
│   ├── version-config.sh       # Version override system
│   ├── project-generator.sh    # Project creation orchestration
│   ├── docker-hub.sh           # Docker Hub utilities
│   ├── git-hooks.sh            # Git hooks installation
│   ├── dependency-manager.sh   # --with-deps handling
│   ├── profiles.sh             # Profile management
│   ├── update.sh               # Self-update functionality
│   └── version.sh              # Version comparison
├── generators/
│   ├── fastapi.sh              # FastAPI backend
│   ├── nextjs.sh               # Next.js frontend
│   ├── minimal-python.sh       # Minimal Python projects
│   ├── minimal-node.sh         # Minimal Node.js projects
│   ├── postgresql.sh           # PostgreSQL database
│   ├── mongodb.sh              # MongoDB database
│   ├── redis.sh                # Redis cache
│   └── chroma.sh               # Chroma vector database
├── templates/
│   ├── requirements/           # Python dependency templates
│   ├── dependencies/           # Node.js dependency templates
│   ├── profiles/               # Project profile definitions
│   └── git-hooks/              # Pre-commit/pre-push hooks
└── install.sh                  # Installation script
```

## Configuration System

Configuration is centralized in `lib/config.sh` (defaults) and `lib/version-config.sh` (override logic).

### Hierarchy (highest to lowest priority)
1. **CLI flags**: `--python-version 3.10`, `--mongodb-version 6.0`, etc.
2. **Profile TOML**: `templates/profiles/*.toml` settings
3. **User config**: `~/.spinbox/config/global.conf`
4. **Built-in defaults**: `lib/config.sh`

### Configurable Versions

| Component | Default | CLI Flag | Config Key |
|-----------|---------|----------|------------|
| Python | 3.11 | `--python-version` | `PYTHON_VERSION` |
| Node.js | 20 | `--node-version` | `NODE_VERSION` |
| PostgreSQL | 15 | `--postgres-version` | `POSTGRES_VERSION` |
| Redis | 7 | `--redis-version` | `REDIS_VERSION` |
| MongoDB | 7.0 | `--mongodb-version` | `MONGODB_VERSION` |
| ChromaDB | latest | `--chroma-version` | `CHROMA_VERSION` |

### Key Files
- `lib/config.sh` - Single source of truth for all defaults
- `lib/version-config.sh` - Getter/setter functions and override logic
- `~/.spinbox/config/global.conf` - User configuration
- `.config/global.conf` - Repository defaults (for development)

### Key Directories
- `~/.spinbox/` - User configuration and cache
- `~/.spinbox/runtime/` - Installed runtime files
- `~/.spinbox/cache/` - Temporary files

## Component System

### Available Components

| Component | Flag | Generator |
|-----------|------|-----------|
| Python | `--python` | `minimal-python.sh` |
| Node.js | `--node` | `minimal-node.sh` |
| FastAPI | `--fastapi` | `fastapi.sh` |
| Next.js | `--nextjs` | `nextjs.sh` |
| PostgreSQL | `--postgresql` | `postgresql.sh` |
| MongoDB | `--mongodb` | `mongodb.sh` |
| Redis | `--redis` | `redis.sh` |
| Chroma | `--chroma` | `chroma.sh` |

### Profiles

Predefined component combinations in `templates/profiles/`:

| Profile | Components |
|---------|------------|
| `python` | Python DevContainer |
| `node` | Node.js DevContainer |
| `web-app` | FastAPI + Next.js + PostgreSQL |
| `api-only` | FastAPI + PostgreSQL + Redis |
| `data-science` | Python + Jupyter + PostgreSQL |
| `ai-llm` | Python + Chroma + Redis |

## Project Generation Flow

```
spinbox create myproject --fastapi --postgresql
    │
    ├── 1. Parse CLI flags (bin/spinbox)
    ├── 2. Load configuration (lib/config.sh)
    ├── 3. Validate project name and path
    ├── 4. Create project directory
    ├── 5. Generate DevContainer config
    ├── 6. Call component generators
    │       ├── fastapi.sh
    │       └── postgresql.sh
    ├── 7. Generate docker-compose.yml
    ├── 8. Initialize Git repository
    ├── 9. Install Git hooks (if applicable)
    └── 10. Display completion message
```

## Installation Architecture

### User Installation (`~/.local/bin/`)
- Installs to user's local bin directory
- Uses `~/.spinbox/runtime/` for runtime files
- No sudo required

### System Installation (`/usr/local/bin/`)
- Installs to system-wide location
- Uses centralized source in `~/.spinbox/`
- Requires sudo

### Atomic Updates
Updates use backup/swap/restore pattern to prevent corruption:
1. Download new version to temp location
2. Backup current installation
3. Swap in new version
4. Remove backup on success, restore on failure

## Command Structure

```bash
# Project creation
spinbox create <name> [flags]      # Create new project
spinbox create <name> --profile X  # Use predefined profile

# Project management
spinbox add <component>            # Add component to existing project
spinbox start                      # Start Docker services
spinbox status                     # Show project status

# Configuration
spinbox config                     # Show current config
spinbox config set KEY VALUE       # Set config value
spinbox profiles                   # List available profiles

# Maintenance
spinbox update                     # Update Spinbox
spinbox --version                  # Show version
```

## Performance

- Project creation: <0.5 seconds typical
- CLI startup: <0.1 seconds
- Memory usage: <50MB during operation

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Language | Shell scripts | Zero dependencies, universal availability, fast |
| Config format | TOML profiles | Human-readable, simple parsing |
| Platforms | macOS + Linux | Simplify maintenance, WSL2 for Windows |
| DevContainers | First-class | Consistent environments, editor support |
