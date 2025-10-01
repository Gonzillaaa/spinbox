# Spinbox Quick Start Guide

Get up and running with Spinbox in 5 minutes! This guide will walk you through installing Spinbox and creating your first prototyping environment.

## 🚀 5-Minute Tutorial

### Step 1: Install Spinbox (2 minutes)

```bash
# Recommended installation (no sudo required)
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install-user.sh | bash
```

**Need help?** See the [detailed installation guide](./installation.md) for platform-specific instructions and troubleshooting.

**Verify installation:**
```bash
spinbox --version
# Should output: Spinbox v0.1.0-beta.8
```

### Step 2: Explore Available Options (30 seconds)

**List available profiles:**
```bash
spinbox profiles
```

**See what components are available:**
```bash
spinbox status --components
```

### Step 3: Create Your First Project (2 minutes)

**Option A: Use a predefined profile (recommended)**
```bash
# Full-stack web application
spinbox create myapp --profile web-app

# Backend API with database
spinbox create api-server --profile api-only

# Data science environment
spinbox create ml-project --profile data-science

# AI/LLM development
spinbox create ai-project --profile ai-llm

# Use Docker Hub for 50-70% faster creation
spinbox create myapp --profile web-app --docker-hub
```

> **💡 Performance Tip**: Add `--docker-hub` to any command for faster project creation. This uses pre-built optimized images instead of building locally.

**Option B: Custom component selection**
```bash
# Simple Python project
spinbox create myproject --python

# Full-stack with specific components
spinbox create webapp --python --node --postgresql --redis
```

### Step 4: Start Development (30 seconds)

**Navigate to your project:**
```bash
cd myapp  # or whatever you named your project
```

**Open in your editor:**
```bash
code .     # VS Code
cursor .   # Cursor
# Click "Reopen in Container" when prompted
```

**Start services (if you created components):**
```bash
spinbox start
```

**🎉 You're ready to develop!** Your project now has:
- DevContainer for consistent prototyping environment
- All selected components configured and ready
- Docker Compose for service orchestration
- Modern prototyping tools pre-installed

## Common First Projects

### Web Application (Full-Stack)

**Create a complete web application with backend, frontend, and database:**
```bash
spinbox create webapp --profile web-app
cd webapp
code .
```

**What you get:**
- FastAPI backend with SQLAlchemy
- Next.js frontend with TypeScript
- PostgreSQL database with PGVector
- DevContainer with all tools configured
- Docker Compose for easy service management

**Next steps:**
```bash
# Start all services
spinbox start

# View service status
docker-compose ps

# View logs
spinbox start --logs
```

### API Development

**Create a backend API with database and caching:**
```bash
spinbox create api-server --profile api-only
cd api-server
code .
```

**What you get:**
- FastAPI backend with async support
- PostgreSQL database
- Redis for caching and queues
- DevContainer with Python 3.11 (configurable)
- Pre-configured prototyping environment

### Data Science Project

**Create a data science environment:**
```bash
spinbox create ml-project --profile data-science
cd ml-project
code .
```

**What you get:**
- Python 3.11+ with data science libraries
- Jupyter notebook support
- pandas, numpy, matplotlib, scikit-learn
- PostgreSQL for data storage
- DevContainer with all ML tools

### AI/LLM Development

**Create an AI prototyping environment:**
```bash
spinbox create ai-project --profile ai-llm
cd ai-project
code .
```

**What you get:**
- Python environment with AI libraries
- OpenAI, Anthropic, LangChain, LlamaIndex
- Chroma vector database for embeddings
- PostgreSQL for data persistence
- DevContainer optimized for AI prototyping

## Essential Commands

### Project Creation
```bash
# With predefined profiles
spinbox create <name> --profile <profile-name>

# With custom components
spinbox create <name> --python --node --postgresql

# With version overrides
spinbox create <name> --profile web-app --python-version 3.11
```

### Project Management
```bash
# Add components to existing project
spinbox add --postgresql --redis

# Start project services
spinbox start                    # Background
spinbox start --logs             # With logs
spinbox start --build            # Rebuild first

# Check project status
spinbox status
```

### Configuration
```bash
# View current configuration
spinbox config --list

# Set default versions
spinbox config --set PYTHON_VERSION=3.11
spinbox config --set NODE_VERSION=18

# Interactive setup
spinbox config --setup
```

### Getting Help
```bash
# General help
spinbox --help

# Command-specific help
spinbox create --help
spinbox add --help
spinbox config --help
```

## Development Workflow

### 1. Create Project
```bash
spinbox create myproject --profile web-app
cd myproject
```

### 2. Open in Editor
```bash
code .  # or cursor .
# Click "Reopen in Container" when prompted
```

### 3. Start Services
```bash
spinbox start
```

### 4. Develop
- Edit code in the DevContainer
- Services run in the background
- Database and other services are automatically configured
- All prototyping tools are pre-installed

### 5. Manage Services
```bash
# View service status
docker-compose ps

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Restart with rebuilding
spinbox start --build --force-recreate
```

## Tips for New Users

### 1. Start with Profiles
Profiles are pre-configured combinations that solve common development scenarios:
- **web-app**: Full-stack web application
- **api-only**: Backend API development
- **data-science**: ML/data science projects
- **ai-llm**: AI and LLM development
- **minimal**: Basic prototyping environment

### 2. Use DevContainers
Every Spinbox project includes a DevContainer configuration:
- Consistent environment across team members
- All tools pre-installed and configured
- No "works on my machine" problems
- Supports VS Code, Cursor, and other editors

### 3. Customize as Needed
```bash
# Override software versions
spinbox create myproject --profile web-app --python-version 3.11

# Add components later
cd myproject
spinbox add --redis --chroma

# Customize global defaults
spinbox config --set PYTHON_VERSION=3.11
```

### 4. Leverage Service Management
```bash
# Start everything in background
spinbox start

# View what's running
docker-compose ps

# See logs from all services
docker-compose logs -f

# Stop when done
docker-compose down
```

## Common Use Cases

### Learning New Technologies
```bash
# Try out FastAPI
spinbox create fastapi-test --fastapi

# Experiment with Next.js
spinbox create nextjs-test --nextjs

# Test full-stack integration
spinbox create fullstack-test --fastapi --nextjs --postgresql
```

### Prototyping
```bash
# Quick API prototype
spinbox create prototype-api --profile api-only

# Full app prototype
spinbox create prototype-app --profile web-app

# AI experiment
spinbox create ai-experiment --profile ai-llm
```

### Team Development
```bash
# Everyone gets the same environment
spinbox create team-project --profile web-app

# Share project, team runs:
cd team-project
spinbox start
code .
```

## Next Steps

### Explore Documentation
- **Installation Guide**: [docs/user/installation.md](./installation.md)
- **CLI Reference**: [docs/user/cli-reference.md](./cli-reference.md)
- **Troubleshooting**: [docs/user/troubleshooting.md](./troubleshooting.md)

### Learn More About Components
- **Adding Components**: [docs/dev/adding-components.md](../dev/adding-components.md)
- **Backend Development**: Check `backend/README.md` in generated projects
- **Frontend Development**: Check `frontend/README.md` in generated projects

### Customize Your Setup
```bash
# Set up global preferences
spinbox config --setup

# Create custom profiles (advanced)
# Edit ~/.spinbox/templates/profiles/custom.toml
```

### Join the Community
- **GitHub Issues**: Report bugs or request features
- **GitHub Discussions**: Ask questions and share projects
- **Documentation**: Contribute to guides and tutorials

## Troubleshooting Quick Fixes

### Spinbox Not Found
```bash
# Check if installed
which spinbox

# Add to PATH
export PATH="/usr/local/bin:$PATH"
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
```

### Docker Issues
```bash
# Check Docker is running
docker --version
docker ps

# Start Docker Desktop
open -a Docker  # macOS
```

### Permission Issues
```bash
# Make executable
chmod +x /usr/local/bin/spinbox

# Fix ownership
sudo chown $USER:$USER /usr/local/bin/spinbox
```

### Configuration Problems
```bash
# Reset and reconfigure
spinbox config --reset global
spinbox config --setup
```

---

**You're all set!** Start building amazing projects with Spinbox. The prototyping environment is ready in seconds, not hours.

**Pro tip**: Try `spinbox create demo --profile web-app` to see a complete full-stack setup in action!