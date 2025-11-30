# Quick Start Guide

Get up and running with Spinbox in 5 minutes.

## Install

```bash
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install-user.sh | bash
spinbox --version
```

Need help? See [Installation Guide](./installation.md).

## Create Your First Project

### Using Profiles (Recommended)

```bash
# Full-stack web app
spinbox create myapp --profile web-app

# API with database
spinbox create api-server --profile api-only

# Data science
spinbox create ml-project --profile data-science

# AI/LLM development
spinbox create ai-project --profile ai-llm
```

**Tip**: Add `--docker-hub` for 50-70% faster creation.

### Using Components

```bash
spinbox create myproject --python
spinbox create webapp --fastapi --nextjs --postgresql
```

## Start Development

```bash
cd myapp
code .     # or cursor .
# Click "Reopen in Container" when prompted
spinbox start
```

**Done!** Your project has:
- DevContainer with all tools
- Docker Compose for services
- Components configured and ready

## Available Profiles

| Profile | Description | Components |
|---------|-------------|------------|
| `python` | Python development | Python + tools |
| `node` | Node.js development | Node.js + TypeScript |
| `web-app` | Full-stack web | FastAPI + Next.js + PostgreSQL |
| `api-only` | Backend API | FastAPI + PostgreSQL + Redis |
| `data-science` | ML/Data science | Python + Jupyter + PostgreSQL |
| `ai-llm` | AI development | Python + Chroma + PostgreSQL |

## Essential Commands

```bash
# List profiles
spinbox profiles

# Add components to existing project
cd myproject
spinbox add --postgresql --redis

# Start/stop services
spinbox start
docker-compose down

# Check status
spinbox status

# Configure defaults
spinbox config --set PYTHON_VERSION=3.12
```

## Next Steps

- [CLI Reference](./cli-reference.md) - Complete command docs
- [Troubleshooting](./troubleshooting.md) - Common issues
- [Git Hooks](./git-hooks.md) - Code quality automation
