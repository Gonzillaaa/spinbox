[logo]: https://github.com/Gonzillaaa/spinbox/blob/main/docs/spinbox-logo-cropped.png "Spinbox"

![Spinbox][logo]

# Spin up containerized prototyping environments in seconds! 

A **global CLI tool** for spinning up customizable development environments with predefined profiles or custom component selection. Uses Docker, DevContainers (compatible with VS Code, Cursor, and other editors), and comes with a modern development setup. Build your stack by selecting any combination of:

- FastAPI backend (Python 3.12+)
- Next.js frontend (TypeScript)
- PostgreSQL database with PGVector
- MongoDB document database
- Redis for caching and queues
- Chroma vector database for embeddings

## 🚀 Features

### **Global CLI Tool**
- **Simple Commands**: `spinbox create myproject --profile web-app`
- **Predefined Profiles**: 5 curated profiles for common development scenarios
- **Custom Components**: Mix and match components as needed
- **Project Management**: Add components, start services, check status

### **Development Environment**
- **DevContainer-First**: Every project includes a DevContainer as the baseline
- **Requirements.txt Templates**: Quick-start templates for different development needs
- **Modern Tech Stack**: Python 3.12+, UV package manager, Node.js 20+, TypeScript
- **Enhanced Developer Experience**:
  - DevContainers for consistency across VS Code, Cursor, and other editors
  - Zsh with Powerlevel10k for a beautiful, functional terminal
  - Pre-configured development tools and shortcuts

### **Component System**
- **Modular Design**: Start minimal, add what you need
- **Service Management**: Built-in Docker Compose orchestration
- **Version Control**: Customize software versions globally or per-project
- **Easy Installation**: Homebrew integration for macOS
- **Root-Level Deployment**: All project files created at repository root

## 📋 Prerequisites

- Docker Desktop
- DevContainer-compatible editor (VS Code, Cursor, etc.)
- Git

## 🏁 Quick Start

### 1. Install Spinbox (One-time)

#### Option A: Quick Install (Recommended)
```bash
# Install Spinbox globally
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh | bash

# Or with Homebrew
brew install https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/Formula/spinbox.rb
```

#### Option B: Manual Install
```bash
# Clone and install
git clone https://github.com/Gonzillaaa/spinbox.git
cd spinbox
chmod +x install.sh
./install.sh
```

### 2. Create Projects with Predefined Profiles

```bash
# Use predefined profiles for common scenarios
spinbox create myapp --profile web-app        # Full-stack web application
spinbox create api-server --profile api-only  # Backend API with database
spinbox create ml-project --profile data-science  # Data science environment
spinbox create ai-project --profile ai-llm    # AI/LLM development

# List available profiles
spinbox profiles

# Show profile details
spinbox profiles web-app
```

### 3. Custom Component Selection

```bash
# Build custom projects by selecting components
spinbox create myproject --python             # Simple Python project
spinbox create webapp --python --node --database  # Custom full-stack
spinbox create api --backend --redis          # API with caching

# Customize versions
spinbox create api --backend --redis --python-version 3.11
```

### 4. Project Management

```bash
# Add components to existing projects
cd myproject
spinbox add --database --redis

# Start project services
spinbox start                    # Start all services in background
spinbox start --logs             # Start and show logs

# Check project status
spinbox status                   # Show project and configuration info

# Manage global configuration
spinbox config --list           # Show current configuration
spinbox config --set PYTHON_VERSION=3.11
```

## 📦 Available Components

- `--python` - Python DevContainer with virtual environment
- `--node` - Node.js DevContainer with TypeScript  
- `--backend` - FastAPI backend (includes Python)
- `--frontend` - Next.js frontend (includes Node.js)
- `--database` - PostgreSQL with PGVector extension
- `--mongodb` - MongoDB document database
- `--redis` - Redis for caching and queues
- `--chroma` - Chroma vector database for embeddings

## 🎯 Predefined Profiles

- **`web-app`** - Full-stack web application with backend, frontend, and database
- **`api-only`** - Backend API with database and Redis caching
- **`data-science`** - Python environment with ML/data science libraries
- **`ai-llm`** - AI development environment with vector database
- **`minimal`** - Basic development environment with essential tools

## 🛠️ Development Workflow

### 1. Open in Editor
```bash
cd myproject
code .     # VS Code
cursor .   # Cursor
# When prompted, click "Reopen in Container"
```

### 2. Start Services (if needed)
```bash
# Start all services in background
spinbox start

# Or use docker-compose directly
docker-compose up -d
```

Your editor will detect the DevContainer configuration and prompt to "Reopen in Container".

---

## 🔄 Alternative: Legacy Script Method

For users who prefer the original workflow or need to use specific versions, the legacy script method is still available:

#### For Existing Codebases:
```bash
cd your-existing-repo/
git clone https://github.com/Gonzillaaa/spinbox.git spinbox/
./spinbox/project-setup.sh
# After setup completes:
rm -rf spinbox/  # Safe to delete!
```

#### For New Projects:
```bash
mkdir new-project && cd new-project/
git clone https://github.com/Gonzillaaa/spinbox.git spinbox/
./spinbox/project-setup.sh
rm -rf spinbox/  # Safe to delete!
```

**Note**: The global CLI method is recommended for most users as it provides better command-line experience and doesn't require temporary directory cloning.

## 🗂️ Structure

### Global Installation Structure
```
/usr/local/bin/spinbox     # Global CLI command
~/.spinbox/                # User configuration directory
├── config/                # Configuration files
└── cache/                 # Cache directory
```

### Scaffolding Directory (Legacy Method)
```
spinbox/
├── bin/spinbox            # CLI entry point
├── install.sh             # Installation script
├── lib/                   # Utility libraries
├── generators/            # Component generators
├── docs/                  # Documentation
├── templates/             # Requirements.txt templates
└── README.md              # This file
```

### After Setup (Permanent)
```
your-repo/
├── backend/               # FastAPI backend (if selected)
├── frontend/              # Next.js frontend (if selected)
├── database/              # PostgreSQL config (if selected)
├── mongodb/               # MongoDB config (if selected)
├── redis/                 # Redis config (if selected)
├── chroma_data/           # Chroma vector database data (if selected)
├── .devcontainer/         # DevContainer config with Dockerfile (always created)
├── docker-compose.yml     # Docker services (if components selected)
├── venv/                  # Python virtual environment (created in DevContainer)
├── requirements.txt       # Python dependencies
├── package.json          # Node.js dependencies (if frontend)
└── README.md             # Project documentation
```

## 🧩 Components

### FastAPI Backend

- Python 3.12+ with type hints
- UV package manager for dependencies
- Virtual environment for isolation
- SQLAlchemy ORM with async support
- Alembic for migrations
- Easy-to-extend structure

### Next.js Frontend

- TypeScript for type safety
- Modern App Router
- Tailwind CSS for styling
- ESLint for code quality
- Optimized for DevContainer development

### PostgreSQL with PGVector

- Vector embedding support
- Initialization scripts for schema setup
- Proper volume configuration
- PGVector extension pre-installed

### MongoDB

- Document database for flexible data storage
- Initialization scripts for collections and indexes
- Authentication enabled
- Volume persistence configured

### Redis

- Configured for caching and queues
- Persistence enabled
- Optimized configuration

### Chroma Vector Database

- Lightweight vector database for embeddings
- Persistent storage for vectors
- Simple REST API for adding and searching documents
- Built-in similarity search

## 📦 Requirements.txt Templates

When setting up a minimal Python project, choose from curated requirements.txt templates:

- **Minimal**: Basic development tools (uv, pytest, black, python-dotenv, requests)
- **Data Science**: pandas, numpy, matplotlib, jupyter, plotly, scikit-learn
- **AI/LLM**: openai, anthropic, langchain, llama-index, tiktoken, transformers
- **Web Scraping**: beautifulsoup4, selenium, scrapy, lxml
- **API Development**: fastapi, uvicorn, pydantic, httpx
- **Custom**: Minimal template you can customize

Perfect for rapid prototyping - get started immediately with the right dependencies!

## 🔄 Adding Components Later

Already set up a project but need to add more components? No problem!

### Using Global CLI (Recommended)

```bash
# In your existing project directory:
spinbox add --backend --redis
spinbox add --database --mongodb
```

**Note**: The `spinbox add` command is planned for Phase 4 implementation.

### Legacy Method

```bash
# In your existing project:
git clone https://github.com/Gonzillaaa/spinbox.git spinbox/
./spinbox/project-setup.sh
# Select additional components you want to add
rm -rf spinbox/
```

The setup script will detect existing components and only add new ones.

### Manual Addition

Follow our detailed guides in the [docs/adding-components.md](./docs/adding-components.md) file.

## ⚙️ Configuration

### Software Version Configuration

Spinbox supports configurable software versions for consistent development environments. Use the global CLI to manage configuration:

```bash
# Set default versions globally
spinbox config --set PYTHON_VERSION=3.11
spinbox config --set NODE_VERSION=18
spinbox config --set POSTGRES_VERSION=14
spinbox config --set REDIS_VERSION=6

# Or edit the configuration file directly
# Located at ~/.spinbox/config/global.conf
```

**Default versions** (used when no configuration exists):
- Python: `3.12`
- Node.js: `20`
- PostgreSQL: `15`
- Redis: `7`

All Docker images, requirements templates, and generated configurations will use your specified versions. The setup script shows which versions are being used:

```
[+] Using configuration: Python 3.11, Node 18, PostgreSQL 14, Redis 6
```

### DevContainers

Your DevContainer configuration is automatically generated based on selected components and works with VS Code, Cursor, and other compatible editors. It includes:

- Appropriate extensions
- Container connections
- Shared volumes
- Development server ports

### Docker Compose

The Docker Compose file is custom-built for your selected components with:

- Inter-service networking
- Volume persistence
- Environment variables
- Port mappings

### Zsh with Powerlevel10k

Every container comes with:

- Beautiful Powerlevel10k theme
- Helpful aliases for common commands
- Syntax highlighting
- Autosuggestions

## 🛠️ Advanced Usage

### Custom Components

The project setup script can be extended to support additional components. Modify `project-setup.sh` to add your own component templates and configuration logic.

### Local Development

Development is designed to happen inside DevContainers for consistency. The virtual environment is automatically created and activated inside the container. However, if you need to work outside containers:

1. **Open in DevContainer** (Recommended):
   - Your editor will prompt to reopen in container
   - Virtual environment is auto-activated
   - All dependencies are pre-installed

2. **Local development** (if needed):
   - Virtual environment must be created manually: `python3 -m venv venv`
   - Activate with: `source venv/bin/activate`

### Cleanup After Setup

Once your project is set up, the `spinbox/` directory serves no purpose:

```bash
rm -rf spinbox/
```

All your development environment files are now at the root level and will continue working normally.

## 🔍 Troubleshooting

See [docs/troubleshooting.md](./docs/troubleshooting.md) for solutions to common issues.

## 📚 Documentation

- [Adding Components](./docs/adding-components.md)
- [Chroma Vector Database Usage](./docs/chroma-usage.md)
- [Troubleshooting](./docs/troubleshooting.md)
- [Performance Optimization](./docs/performance.md)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
