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

Uses Docker, DevContainers (compatible with VS Code, Cursor, and other editors), and comes with a modern prototyping setup. Build your stack by selecting any combination of:

**Application Frameworks**

- FastAPI backend framework (Python 3.12+)
- Next.js frontend framework (TypeScript)

**Workflow Frameworks**

- Data Science workflow (Jupyter, pandas, scikit-learn, ML libraries)
- AI/ML workflow (LLMs, agents, vector processing, embeddings)

**Infrastructure Services**

- PostgreSQL database with PGVector
- MongoDB document database
- Redis for caching and queues
- Chroma vector database for embeddings

**Foundation Environments**

- Python DevContainer with virtual environment
- Node.js DevContainer with TypeScript

## 🚀 Features

### **Global CLI Tool**

- **Simple Commands**: `spinbox create myproject --profile web-app`
- **Predefined Profiles**: 5 curated profiles for common development scenarios:
  - **web-app**: FastAPI backend + Next.js frontend + PostgreSQL (full-stack web app)
  - **api-only**: FastAPI backend + PostgreSQL + Redis (API with caching)
  - **data-science**: Data Science workflow + PostgreSQL (data analysis with storage)
  - **ai-llm**: AI/ML workflow + Chroma (AI/LLM with vector search)
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
spinbox create api-server --profile api-only  # FastAPI API with PostgreSQL
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
spinbox create webapp --python --node --postgresql  # Custom full-stack
spinbox create api --fastapi --redis          # API layer with caching

# Customize versions
spinbox create api --fastapi --redis --python-version 3.11

# Add dependencies and examples
spinbox create api --fastapi --with-deps --with-examples
spinbox create fullstack --fastapi --nextjs --postgresql --with-deps --with-examples
```

### 4. Project Management

```bash
# Add components to existing projects
cd myproject
spinbox add --postgresql --redis
spinbox add --data-science --with-examples
spinbox add --ai-ml --chroma --with-deps

# Add with dependencies and examples
spinbox add --redis --with-deps --with-examples

# Start project services
spinbox start                    # Start all services in background
spinbox start --logs             # Start and show logs

# Check project status
spinbox status                   # Show project and configuration info

# Update Spinbox
spinbox update                   # Update to latest version
spinbox update --check           # Check for updates

# Manage global configuration
spinbox config --list           # Show current configuration
spinbox config --set PYTHON_VERSION=3.11

# Uninstall Spinbox
spinbox uninstall --config       # Remove Spinbox and configuration
```

## 📦 Available Components

Components are organized by their **architectural role**:

| Component                                                  | Flag             | Architectural Role | Description                                         |
| ---------------------------------------------------------- | ---------------- | ------------------ | --------------------------------------------------- |
| **Application Frameworks** (Build user interfaces)         |
| FastAPI                                                    | `--fastapi`      | Backend Framework  | FastAPI backend with SQLAlchemy (includes Python)   |
| Next.js                                                    | `--nextjs`       | Frontend Framework | Next.js frontend with TypeScript (includes Node.js) |
| **Workflow Frameworks** (Specialized work methodologies)   |
| Data Science                                               | `--data-science` | Data Workflow      | Jupyter, pandas, scikit-learn, ML libraries         |
| AI/ML                                                      | `--ai-ml`        | AI Workflow        | LLMs, agents, vector processing, embeddings         |
| **Infrastructure Services** (Data storage & core services) |
| PostgreSQL                                                 | `--postgresql`   | Primary Storage    | PostgreSQL with PGVector extension                  |
| MongoDB                                                    | `--mongodb`      | Document Storage   | MongoDB document database                           |
| Redis                                                      | `--redis`        | Caching Layer      | Redis for caching and queues                        |
| Chroma                                                     | `--chroma`       | Vector Search      | Chroma vector database for AI/ML                    |
| **Foundation Environments** (Base containers)              |
| Python                                                     | `--python`       | DevContainer       | Python DevContainer with virtual environment        |
| Node.js                                                    | `--node`         | DevContainer       | Node.js DevContainer with TypeScript                |

### 🎯 Enhancement Flags

| Flag              | Description                                  | Usage                                   |
| ----------------- | -------------------------------------------- | --------------------------------------- |
| `--with-deps`     | Automatically install component dependencies | Uses `uv` for Python, `npm` for Node.js |
| `--with-examples` | Generate starter project templates          | Creates functional boilerplate code     |

**Examples:**

```bash
# Application frameworks (build user interfaces)
spinbox create api --fastapi --with-deps
spinbox create frontend --nextjs --with-examples

# Workflow frameworks (specialized methodologies)
spinbox create analysis --data-science --with-deps --with-examples
spinbox create ai-project --ai-ml --with-deps --with-examples

# Combined projects
spinbox create webapp --fastapi --nextjs --postgresql --with-deps --with-examples
```

**Examples of combining components:**

- `--postgresql --redis` - Primary storage + caching
- `--mongodb --chroma` - Document storage + vector search
- `--fastapi --nextjs --postgresql` - Full-stack web application
- `--data-science --postgresql` - Data analysis workflow with database
- `--ai-ml --chroma` - AI/ML workflow with vector database

## 🎯 Predefined Profiles

| Profile        | Description                   | Components                  |
| -------------- | ----------------------------- | --------------------------- |
| `web-app`      | Full-stack web application    | fastapi, nextjs, postgresql |
| `api-only`     | FastAPI API with caching      | fastapi, postgresql, redis  |
| `data-science` | Data science workflow         | data-science, postgresql    |
| `ai-llm`       | AI/LLM workflow               | ai-ml, chroma               |
| `minimal`      | Basic prototyping environment | python                      |

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

**Application Frameworks:**

- **FastAPI** - Python 3.12+ with type hints, UV package manager, SQLAlchemy ORM with async support
- **Next.js** - TypeScript, modern App Router, Tailwind CSS, ESLint

**Workflow Frameworks:**

- **Data Science** - Jupyter Lab, pandas, scikit-learn, matplotlib, automated analysis scripts
- **AI/ML** - LLM clients (OpenAI, Anthropic), agent frameworks, vector processing, prompt management

**Infrastructure Services:**

- **PostgreSQL** - PGVector extension for vector embeddings, initialization scripts
- **MongoDB** - Document database with authentication, collections and indexes
- **Redis** - Caching and queues with persistence enabled
- **Chroma** - Vector database for embeddings with persistent storage

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

See [docs/adding-components.md](./docs/adding-components.md) for detailed guides.

## 🔧 Git Hooks Integration

Spinbox provides project-aware git hooks for automated quality assurance:

```bash
# Install git hooks for your project
spinbox hooks add all

# Install with example configurations
spinbox hooks add all --with-examples

# Manage hooks
spinbox hooks list                    # List installed hooks
spinbox hooks remove all             # Remove hooks
```

**What hooks provide:**

- **Pre-commit**: Fast formatting and lint checks (< 5 seconds)
- **Pre-push**: Comprehensive tests and security validation
- **Project-aware**: Automatically detects Python, Node.js, FastAPI, Next.js projects
- **Quality gates**: Prevents commits/pushes with formatting or test failures

See [docs/git-hooks.md](./docs/git-hooks.md) for complete documentation.

## ⚙️ Configuration

### Software Version Configuration

```bash
# Set default versions globally
spinbox config --set PYTHON_VERSION=3.11
spinbox config --set NODE_VERSION=18
spinbox config --set POSTGRES_VERSION=14

# View current configuration
spinbox config --list
```

**Default versions**: Python 3.12, Node.js 20, PostgreSQL 15, Redis 7

### DevContainers & Docker Compose

- **DevContainer**: Automatically configured for VS Code, Cursor, and other editors
- **Docker Compose**: Custom-built with networking, volumes, and environment variables
- **Zsh with Powerlevel10k**: Beautiful terminal with helpful aliases and syntax highlighting

## 🛠️ Advanced Usage

### Custom Components

Spinbox uses a modular generator system. You can extend it by:

- Adding new generators in the `generators/` directory
- Creating custom profiles in `templates/profiles/`
- Customizing requirements in `templates/requirements/`

### Local Development

**Recommended**: Open in DevContainer for consistency

- Virtual environment is auto-activated
- All dependencies pre-installed
- Editor extensions configured

**Alternative**: Manual setup outside container

- Create virtual environment: `python3 -m venv venv`
- Activate: `source venv/bin/activate`

## 🔍 Troubleshooting

See [docs/troubleshooting.md](./docs/troubleshooting.md) for solutions to common issues.

## 📚 Documentation

- [Quick Start Guide](./docs/quick-start.md)
- [CLI Reference](./docs/cli-reference.md)
- [Adding Components](./docs/adding-components.md)
- [Git Hooks Integration](./docs/git-hooks.md)
- [Installation Guide](./docs/installation.md)
- [Troubleshooting](./docs/troubleshooting.md)

See [docs/README.md](./docs/README.md) for complete documentation index.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
