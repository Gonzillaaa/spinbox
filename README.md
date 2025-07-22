[logo]: https://github.com/Gonzillaaa/spinbox/blob/main/docs/spinbox-logo-cropped.png 'Spinbox'

![Spinbox][logo]

# Spin up containerized prototyping environments in seconds!

Spinbox is a **global CLI tool** for creating customizable prototyping environments using Docker and DevContainers. Build your stack by selecting from predefined profiles or mixing and matching components to create the perfect prototyping environment.

## 🚀 Key Features

- **Global CLI Tool**: Simple commands like `spinbox create myproject --profile web-app`
- **DevContainer-First**: Every project includes DevContainer configuration for VS Code, Cursor, and other editors
- **Docker Hub Integration**: 50-70% faster project creation with pre-built optimized images
- **Automatic Dependencies**: Use `--with-deps` flag to automatically manage Python and Node.js packages
- **Modular Components**: Mix and match languages, frameworks, and databases
- **Predefined Profiles**: 6 curated profiles for common development scenarios
- **Security Built-in**: Virtual environments, .env templates, and security best practices
- **Zero Config**: Sensible defaults with full customization when needed

## 📋 Prerequisites

- Docker Desktop
- Git
- DevContainer-compatible editor (VS Code, Cursor, etc.)

## 🏁 Quick Start

### 1. Install Spinbox

```bash
# User install (recommended - no sudo required)
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install-user.sh | bash

# Or system install (requires sudo)
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh | sudo bash
```

**For detailed installation instructions and troubleshooting, see [Installation Guide](./docs/user/installation.md).**

### 2. Create Your First Project

**Using predefined profiles:**

```bash
# Full-stack web application
spinbox create myapp --profile web-app

# API server with caching
spinbox create api-server --profile api-only

# AI/LLM development
spinbox create ai-project --profile ai-llm

# Simple Python project
spinbox create python-project --profile python

# Simple Node.js project
spinbox create node-project --profile node
```

**Fast creation with Docker Hub (50-70% faster):**

```bash
# Add --docker-hub flag to any project for faster creation
spinbox create myapp --profile web-app --docker-hub
spinbox create api-server --fastapi --postgresql --docker-hub
```

**Custom component selection:**

```bash
# Simple Python project
spinbox create myproject --python

# API with caching
spinbox create api --fastapi --redis

# Full-stack custom
spinbox create webapp --fastapi --nextjs --postgresql

# Workflow automation
spinbox create automation --n8n --postgresql
```

**With automatic dependency management:**

```bash
# FastAPI project with automatic dependencies
spinbox create myapi --fastapi --with-deps

# Full-stack with all dependencies included
spinbox create webapp --fastapi --nextjs --postgresql --with-deps

# AI/LLM project with comprehensive dependencies
spinbox create ai-project --fastapi --chroma --with-deps

# Add components with dependencies to existing project
spinbox add --redis --mongodb --with-deps
```

### 3. Start Development

```bash
cd myproject
code .      # Open in VS Code
# Click "Reopen in Container" when prompted
```

## 🧩 Component Architecture

Spinbox components are organized into three architectural layers:

### 1. **DevContainer/Base Layer** (Foundation)

| Component | Flag       | Description                                        |
| --------- | ---------- | -------------------------------------------------- |
| Python    | `--python` | Python 3.12+ DevContainer with virtual environment |
| Node.js   | `--node`   | Node.js 20+ DevContainer with TypeScript           |

### 2. **Application Layer** (API & UI)

| Component | Flag        | Port | Description                                             |
| --------- | ----------- | ---- | ------------------------------------------------------- |
| FastAPI   | `--fastapi` | 8000 | Modern Python API framework (includes Python base)      |
| Next.js   | `--nextjs`  | 3000 | React framework with TypeScript (includes Node.js base) |

### 3. **Storage Layer** (Data Persistence)

| Component  | Flag           | Port  | Architectural Role  | Best For                                      |
| ---------- | -------------- | ----- | ------------------- | --------------------------------------------- |
| PostgreSQL | `--postgresql` | 5432  | Primary Storage     | Relational data, with PGVector for embeddings |
| MongoDB    | `--mongodb`    | 27017 | Alternative Storage | Document-oriented data, flexible schemas      |
| Redis      | `--redis`      | 6379  | Caching Layer       | High-performance caching and queues           |
| Chroma     | `--chroma`     | -     | Vector Search       | AI/ML embeddings and similarity search        |

### 4. **Automation Layer** (Workflow & Integration)

| Component | Flag    | Port | Architectural Role    | Best For                                      |
| --------- | ------- | ---- | --------------------- | --------------------------------------------- |
| n8n       | `--n8n` | 5678 | Workflow Automation   | API integration, data pipelines, task automation |

### Component Combinations

**Common patterns:**

- `--postgresql --redis` → Primary storage + caching layer
- `--mongodb --chroma` → Document storage + vector search
- `--fastapi --nextjs --postgresql` → Full-stack web application
- `--fastapi --redis` → API with caching/queue support
- `--n8n --postgresql` → Workflow automation with persistent storage

## 🎯 Predefined Profiles

| Profile        | Description                                                                | Components                     | Use Case                   |
| -------------- | -------------------------------------------------------------------------- | ------------------------------ | -------------------------- |
| `python`       | Python development with essential tools                                    | Python + testing tools         | Simple Python projects     |
| `node`         | Node.js development with TypeScript                                        | Node.js + TypeScript + testing | Simple Node.js projects    |
| `web-app`      | Full-stack web application                                                 | FastAPI + Next.js + PostgreSQL | Complete web applications  |
| `api-only`     | API server with caching                                                    | FastAPI + PostgreSQL + Redis   | Backend API services       |
| `data-science` | Data science with pandas, numpy, matplotlib, Jupyter, scikit-learn, plotly | Python + PostgreSQL            | Data science and analytics |
| `ai-llm`       | AI/LLM with OpenAI, Anthropic, LangChain, Transformers, Chroma             | Python + PostgreSQL + Chroma   | AI and machine learning    |

```bash
# List all profiles
spinbox profiles

# Show profile details
spinbox profiles web-app
```

## 📦 Automatic Dependency Management

Spinbox supports automatic dependency management for Python and Node.js projects using the `--with-deps` flag.

### Supported Components

**Python Components:**
- **FastAPI**: fastapi, uvicorn, pydantic, python-dotenv
- **PostgreSQL**: sqlalchemy, asyncpg, alembic, psycopg2-binary
- **Redis**: redis, celery
- **Chroma**: chromadb, sentence-transformers
- **MongoDB**: beanie, motor
- **AI/LLM**: openai, anthropic, langchain, llama-index, tiktoken

**Node.js Components:**
- **Next.js**: next, react, react-dom, axios, @types/node, typescript, eslint
- **Express**: express, cors, helmet, morgan, @types/express
- **TailwindCSS**: tailwindcss, autoprefixer, postcss

### Example Usage

```bash
# Create FastAPI project with automatic dependencies
spinbox create myapi --fastapi --with-deps
# Result: Creates requirements.txt with FastAPI dependencies

# Full-stack with all dependencies
spinbox create webapp --fastapi --nextjs --postgresql --with-deps
# Result: Python and Node.js dependencies automatically configured

# Add components with dependencies
spinbox add --redis --chroma --with-deps
# Result: Adds Redis and Chroma packages to existing project
```

After creation, install dependencies:
```bash
# Python projects
pip install -r requirements.txt

# Node.js projects  
npm install
```

## 🛠️ CLI Commands

### Project Creation

```bash
spinbox create <name> [options]
  --profile <profile>        # Use predefined profile
  --python, --node          # Base environments
  --fastapi, --nextjs       # Application frameworks
  --postgresql, --mongodb   # Databases
  --redis, --chroma         # Additional storage
  --with-deps               # Automatic dependency management
  --dry-run                 # Preview without creating
```

### Project Management

```bash
# Add components to existing project
spinbox add --postgresql --redis --with-deps

# Start services
spinbox start              # Start all services
spinbox start --logs       # Start with logs

# Check status
spinbox status             # Show project info

# Update Spinbox
spinbox update             # Update to latest
spinbox update --check     # Check for updates
```

### Configuration

```bash
# View configuration
spinbox config --list

# Set default versions
spinbox config --set PYTHON_VERSION=3.11
spinbox config --set NODE_VERSION=18

# Uninstall
spinbox uninstall --config  # Remove Spinbox and config
```

## 🗂️ Project Structure

```
your-project/
├── .devcontainer/         # DevContainer configuration (always created)
├── fastapi/              # FastAPI backend (if selected)
│   ├── app/
│   ├── requirements.txt
│   └── setup_venv.sh     # Virtual environment setup
├── nextjs/               # Next.js frontend (if selected)
│   ├── src/
│   └── package.json
├── postgresql/           # PostgreSQL config (if selected)
├── mongodb/              # MongoDB config (if selected)
├── redis/                # Redis config (if selected)
├── chroma_data/          # Chroma persistent storage (if selected)
├── docker-compose.yml    # Service orchestration
├── .env                  # Environment variables (from .env.example)
├── .gitignore           # Version control exclusions
└── README.md            # Project documentation
```

## 🛡️ Security Features

- **Environment Isolation**: Each project runs in isolated Docker containers
- **Virtual Environments**: Automatic Python venv with `setup_venv.sh`
- **Secret Management**: Comprehensive .env templates with security guidelines
- **Version Control Safety**: Pre-configured .gitignore prevents credential commits
- **Secure Defaults**: Production-ready security configurations

## 📦 Requirements.txt Templates

For Python projects, choose from curated dependency templates:

- **Minimal**: Basic tools (pytest, black, python-dotenv, requests)
- **Data Science**: pandas, numpy, matplotlib, jupyter, scikit-learn
- **AI/LLM**: openai, anthropic, langchain, llama-index, transformers
- **Web Scraping**: beautifulsoup4, selenium, scrapy, lxml
- **API Development**: fastapi, uvicorn, pydantic, httpx
- **Custom**: Start with minimal and add your own

## 🔧 Advanced Features

### Version Configuration

```bash
# Override default versions
spinbox create api --python-version 3.11 --node-version 18

# Set global defaults
spinbox config --set PYTHON_VERSION=3.11
```

### DevContainer Features

- Zsh with Powerlevel10k theme
- Pre-configured VS Code extensions
- Git aliases and helpers
- Docker-in-Docker support
- Syntax highlighting and auto-completion

### Extending Spinbox

- Add custom generators in `generators/`
- Create new profiles in `templates/profiles/`
- Customize requirements in `templates/requirements/`

## 📚 Documentation

- [Quick Start Guide](./docs/user/quick-start.md)
- [CLI Reference](./docs/user/cli-reference.md)
- [Installation Guide](./docs/user/installation.md)
- [Dependency Management](./docs/user/dependency-management.md)
- [Adding Components](./docs/dev/adding-components.md)
- [Troubleshooting](./docs/user/troubleshooting.md)

See [docs/README.md](./docs/README.md) for complete documentation index.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
