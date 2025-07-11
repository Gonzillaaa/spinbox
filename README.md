[logo]: https://github.com/Gonzillaaa/spinbox/blob/main/docs/spinbox-logo-cropped.png 'Spinbox'

![Spinbox][logo]

# Spin up a containerized prototyping box in seconds!

A **global CLI tool** for spinning up customizable prototyping boxes with predefined profiles or custom component selection.

<p align="left">
  <img src="https://img.shields.io/badge/Docker-blue?logo=docker&logoColor=white" alt="Docker" />
  <img src="https://img.shields.io/badge/DevContainer-0078D4?logo=visualstudiocode&logoColor=white" alt="DevContainer" />
  <img src="https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white" alt="Python" />
  <img src="https://img.shields.io/badge/Node.js-339933?logo=node.js&logoColor=white" alt="Node.js" />
  <img src="https://img.shields.io/badge/FastAPI-009688?logo=fastapi&logoColor=white" alt="FastAPI" />
  <img src="https://img.shields.io/badge/Next.js-000000?logo=next.js&logoColor=white" alt="Next.js" />
  <img src="https://img.shields.io/badge/PostgreSQL-4169E1?logo=postgresql&logoColor=white" alt="PostgreSQL" />
  <img src="https://img.shields.io/badge/MongoDB-47A248?logo=mongodb&logoColor=white" alt="MongoDB" />
  <img src="https://img.shields.io/badge/Redis-DC382D?logo=redis&logoColor=white" alt="Redis" />
  <img src="https://img.shields.io/badge/Chroma-FFB300?logo=google-chrome&logoColor=white" alt="Chroma" />
  <img src="https://img.shields.io/badge/Jupyter-F37626?logo=jupyter&logoColor=white" alt="Jupyter" />
  <img src="https://img.shields.io/badge/TypeScript-3178C6?logo=typescript&logoColor=white" alt="TypeScript" />
</p>

Uses Docker, DevContainers (compatible with VS Code, Cursor, and other editors), and comes with a modern prototyping setup. Choose from **10 modular components** organized by architectural role:

- **Application Frameworks** (2): FastAPI, Next.js
- **Workflow Frameworks** (2): Data Science, AI/ML  
- **Infrastructure Services** (4): PostgreSQL, MongoDB, Redis, Chroma
- **Foundation Environments** (2): Python, Node.js

## 🚀 Features

### **Global CLI Tool**

- **Simple Commands**: `spinbox create myproject --profile web-app`
- **Predefined Profiles**: 5 curated profiles for common development scenarios:
  - **web-app**: FastAPI backend + Next.js frontend + PostgreSQL (full-stack web app)
  - **api-only**: FastAPI backend + PostgreSQL + Redis (API with caching)
  - **data-science**: Data Science workflow + PostgreSQL (data analysis with storage)
  - **ai-llm**: AI/ML workflow + Chroma (OpenAI/Anthropic + LangChain/LlamaIndex + vector search)
  - **minimal**: Python DevContainer only (basic prototyping)
- **Custom Components**: Mix and match components as needed
- **Project Management**: Add components, start services, check status

### **Prototyping Environment**

- **DevContainer-First**: Every project includes a DevContainer as the baseline
- **Requirements.txt Templates**: Quick-start templates for different prototyping needs
- **Modern Tech Stack**: Python 3.12+, UV package manager, Node.js 20+, TypeScript
- **Enhanced Developer Experience**:
  - DevContainers for consistency across VS Code, Cursor, and other editors
  - Zsh with Powerlevel10k for a beautiful, functional terminal
  - Pre-configured prototyping tools and shortcuts

### **Component System**

- **Modular Design**: Start minimal, add what you need
- **Service Management**: Built-in Docker Compose orchestration
- **Version Control**: Customize software versions globally or per-project
- **Dependency Management**: Automatic dependency installation with `--with-deps`
- **Starter Project Templates**: Functional starter code with `--with-examples`
- **Git Hooks Integration**: Automated quality assurance with `spinbox hooks`
- **Easy Installation**: Homebrew integration for macOS
- **Root-Level Deployment**: All project files created at repository root

## 🛡️ Security Features

- **Environment Isolation**: Each project runs in its own Docker container
- **Virtual Environment Setup**: Automatic Python venv creation with `setup_venv.sh`
- **Secret Management**: Comprehensive .env templates with security guidelines
- **Version Control**: Automatic .gitignore generation (prevents .env commits)
- **Configuration Management**: Environment-specific config files
- **Clean Separation**: Development tools separate from production
- **Security Best Practices**: Built-in reminders and secure defaults

## 📋 Prerequisites

- Docker Desktop
- DevContainer-compatible editor (VS Code, Cursor, etc.)
- Git

## 🏁 Quick Start

### 1. Install Spinbox

```bash
# Quick install (recommended)
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh | bash

# Or with Homebrew
brew install https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/Formula/spinbox.rb
```

### 2. Create Your First Project

```bash
# Use predefined profiles for common scenarios
spinbox create myapp --profile web-app        # Full-stack web app
spinbox create api --profile api-only         # High-performance API
spinbox create ml-project --profile data-science  # Data science environment
spinbox create ai-project --profile ai-llm    # AI/LLM development

# Or build custom projects
spinbox create myproject --python --postgresql --with-examples
```

### 3. Start Development

```bash
cd myproject
code .              # Open in VS Code (click "Reopen in Container")
spinbox start       # Start services in background
```

**Complete Guide:** See [Quick Start Tutorial](./docs/user/quick-start.md) for detailed walkthrough and [CLI Reference](./docs/user/cli-reference.md) for all commands.

## 📋 Command Reference

**Project Management:**
- `spinbox create <name> --profile <profile>` - Create new projects with predefined profiles
- `spinbox add --<component>` - Add components to existing projects  
- `spinbox start` - Start project services with Docker Compose
- `spinbox status` - Show project and configuration status

**Configuration & Information:**
- `spinbox config --set <key>=<value>` - Configure global settings
- `spinbox profiles` - List available predefined profiles
- `spinbox update` - Update Spinbox to latest version
- `spinbox hooks add all` - Install git hooks for quality assurance

**Complete Reference:** See [CLI Reference](./docs/user/cli-reference.md) for detailed options and examples.

## 🏗️ Architecture Benefits

**5-Tier Component System:**
- **Application Frameworks** (2) - FastAPI, Next.js for user interfaces
- **Workflow Frameworks** (2) - Data Science, AI/ML for specialized methodologies  
- **Infrastructure Services** (4) - PostgreSQL, MongoDB, Redis, Chroma for data storage
- **Platform Services** (0) - Reserved for future platform integrations
- **Foundation Environments** (2) - Python, Node.js base containers

**Key Advantages:**
- **Modular Design** - Mix and match components as needed
- **DevContainer-First** - Consistent development environments
- **Docker Compose** - Orchestrated multi-service applications
- **Modern Stack** - Latest versions with best practices built-in

## 📦 Component Architecture

**Enhancement Flags:**
- `--with-deps` - Automatically install component dependencies
- `--with-examples` - Generate starter project templates

**Common Combinations:**
- `--fastapi --nextjs --postgresql` - Full-stack web application
- `--data-science --postgresql` - Data analysis with database storage
- `--ai-ml --chroma` - AI/ML workflow with vector search

## 🎯 Predefined Profiles

| Profile | What's Included | Perfect For | Command |
|---------|----------------|-------------|---------|
| **web-app** | FastAPI + Next.js + PostgreSQL | Full-stack web applications | `spinbox create myapp --profile web-app` |
| **api-only** | FastAPI + PostgreSQL + Redis | High-performance API backends | `spinbox create api --profile api-only` |
| **data-science** | Jupyter + pandas + scikit-learn + PostgreSQL | Data analysis & ML workflows | `spinbox create analysis --profile data-science` |
| **ai-llm** | OpenAI + LangChain + LlamaIndex + ChromaDB | AI/LLM applications | `spinbox create ai-proj --profile ai-llm` |
| **minimal** | Python DevContainer + essential tools | Simple scripts & prototypes | `spinbox create basic --profile minimal` |

**Profile Details:** See [CLI Reference](./docs/user/cli-reference.md#available-profiles) for comprehensive descriptions and use cases.

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

### 3. Security Setup

**Python Projects:**

```bash
cd fastapi
./setup_venv.sh  # Sets up virtual environment with security best practices
```

**Environment Variables:**

- Review and update `.env` files with your actual credentials
- Never commit `.env` files to version control (already in .gitignore)
- Use strong passwords and secure API keys

---

## 🗂️ Project Structure

### After Project Creation

```
your-project/
├── fastapi/               # FastAPI application framework (if selected)
├── nextjs/                # Next.js application framework (if selected)
├── data-science/          # Data Science workflow framework (if selected)
├── ai-ml/                 # AI/ML workflow framework (if selected)
├── postgresql/            # PostgreSQL infrastructure service (if selected)
├── mongodb/               # MongoDB infrastructure service (if selected)
├── redis/                 # Redis infrastructure service (if selected)
├── chroma_data/           # Chroma infrastructure service (if selected)
├── .devcontainer/         # DevContainer config (always created)
├── docker-compose.yml     # Docker services (if components selected)
├── requirements.txt       # Python dependencies
├── package.json          # Node.js dependencies (if Next.js)
└── README.md             # Project documentation
```

## 🧩 Component Details

**Application Frameworks (Build user interfaces):**

- **FastAPI** - Python 3.12+ with type hints, UV package manager, SQLAlchemy ORM with async support
- **Next.js** - TypeScript, modern App Router, Tailwind CSS, ESLint

**Workflow Frameworks (Specialized work methodologies):**

- **Data Science** - Jupyter Lab, pandas, scikit-learn, matplotlib, ready-to-use Python scripts
- **AI/ML** - OpenAI/Anthropic clients, LangChain/LlamaIndex agents, ChromaDB vector store, transformers, prompt templates

**Infrastructure Services (Data storage & core services):**

- **PostgreSQL** - PGVector extension for vector embeddings, initialization scripts
- **MongoDB** - Document database with authentication, collections and indexes
- **Redis** - Caching and queues with persistence enabled
- **Chroma** - Vector database for embeddings with persistent storage

**Foundation Environments (Base containers):**

- **Python** - Python DevContainer with virtual environment, UV package manager, modern tooling
- **Node.js** - Node.js DevContainer with TypeScript, npm/yarn support, development tools

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

```bash
# In your existing project directory:
spinbox add --postgresql --redis        # Add primary storage + caching layer
spinbox add --mongodb --chroma        # Add alternative storage + vector search
spinbox add --fastapi --nextjs      # Add API layer + web interface
```

See [docs/user/adding-components.md](./docs/user/adding-components.md) for detailed guides.

## 🔧 Git Hooks Integration

Automated quality assurance with project-aware git hooks:

```bash
spinbox hooks add all                 # Install all recommended hooks
spinbox hooks add all --with-examples # Include example configurations
```

**Features:** Pre-commit formatting, pre-push testing, project-aware detection, quality gates

**Details:** See [Git Hooks Guide](./docs/user/git-hooks.md) for complete documentation.

## ⚙️ Configuration

**Default versions**: Python 3.12, Node.js 20, PostgreSQL 15, Redis 7

```bash
spinbox config --set PYTHON_VERSION=3.11  # Customize versions
spinbox config --list                     # View current settings
```

**DevContainer Features**: VS Code/Cursor integration, Docker Compose orchestration, Zsh with Powerlevel10k

## 🛠️ Advanced Usage

**Custom Components**: Extend Spinbox by adding generators in `generators/`, creating custom profiles in `templates/profiles/`, or customizing requirements in `templates/requirements/`

**Local Development**: Use DevContainer for consistency (recommended) or manual setup with `python3 -m venv venv && source venv/bin/activate`

## 🔍 Troubleshooting

See [docs/user/troubleshooting.md](./docs/user/troubleshooting.md) for solutions to common issues.

## 📚 Documentation

**User Documentation:**
- [Quick Start Guide](./docs/user/quick-start.md)
- [CLI Reference](./docs/user/cli-reference.md)
- [Adding Components](./docs/user/adding-components.md)
- [Git Hooks Integration](./docs/user/git-hooks.md)
- [Installation Guide](./docs/user/installation.md)
- [Troubleshooting](./docs/user/troubleshooting.md)

**Developer Documentation:**
- [Implementation Strategy](./docs/dev/implementation-strategy.md)
- [Global CLI Strategy](./docs/dev/global-cli-strategy.md)
- [Development Backlog](./docs/dev/backlog.md)
- [Release Process](./docs/dev/release-process.md)

See [docs/README.md](./docs/README.md) for complete documentation index.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
