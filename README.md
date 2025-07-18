[logo]: https://github.com/Gonzillaaa/spinbox/blob/main/docs/spinbox-logo-cropped.png 'Spinbox'

![Spinbox][logo]

# Spin up containerized prototyping environments in seconds!

**Spinbox** is a powerful CLI tool that eliminates the friction of setting up development environments. Instead of spending hours configuring Docker, databases, and frameworks, Spinbox creates production-ready prototyping environments in under 5 seconds.

## 🎯 Why Spinbox?

**The Problem**: Setting up a new project with FastAPI, PostgreSQL, Redis, and proper DevContainer configuration takes 2-3 hours of copying boilerplate, writing Docker files, and debugging configuration issues.

**The Solution**: Spinbox does it all in one command:
```bash
spinbox create myproject --fastapi --postgresql --redis --with-examples --with-deps
```

**The Result**: A complete, working development environment with:
- ✅ Configured DevContainer ready for VS Code/Cursor
- ✅ All services running in Docker Compose
- ✅ **Automatic dependency management** - all packages added to requirements.txt/package.json
- ✅ **Working code examples** demonstrating best practices
- ✅ **Installation scripts** for easy dependency setup
- ✅ Security best practices (`.env` files, `.gitignore`, virtual environments)
- ✅ Zero manual configuration required

## 🚀 What Makes Spinbox Different

**DevContainer-First Architecture**: Every project includes complete DevContainer configuration, ensuring consistent development environments across your team.

**Real Working Code**: Unlike scaffolding tools that create empty files, Spinbox includes production-ready examples for every component combination.

**Zero Configuration**: Sensible defaults for everything, with full customization available when needed.

**Modular Design**: Mix and match components to create exactly the stack you need.

**Security Built-in**: Proper `.env` file handling, secure defaults, and security best practices from day one.

## 🚀 Key Features

- **Global CLI Tool**: Simple commands like `spinbox create myproject --profile web-app`
- **DevContainer-First**: Every project includes DevContainer configuration for VS Code, Cursor, and other editors
- **Automatic Dependency Management**: `--with-deps` flag automatically adds packages to requirements.txt/package.json
- **Working Code Examples**: `--with-examples` flag includes production-ready code examples
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

**Option A: User install (recommended):**

```bash
# Install to ~/.local/bin (no sudo required, automatic PATH setup)
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install-user.sh | bash
```

**Note:** The user installation automatically adds `~/.local/bin` to your PATH by detecting your shell and updating the appropriate profile file (.zshrc, .bashrc, etc.). Just restart your terminal or run `source ~/.bashrc` after installation.

**Option B: System install:**

```bash
# Install to /usr/local/bin (requires sudo)
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh | sudo bash
```

**Note:** Installs to `/usr/local/bin` (usually in PATH), requires `sudo`, and does not update your shell profile.

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

**Custom component selection:**

```bash
# Simple Python project
spinbox create myproject --python

# API with caching
spinbox create api --fastapi --redis

# Full-stack custom
spinbox create webapp --fastapi --nextjs --postgresql

# Add working examples to any project
spinbox create myproject --profile web-app --with-examples

# Combine dependencies and examples for complete setup
spinbox create fullstack --fastapi --nextjs --postgresql --with-deps --with-examples
```

### 💡 Working Examples

Spinbox includes production-ready code examples for every component and combination:

```bash
# Create API with working CRUD examples
spinbox create api --fastapi --postgresql --with-examples

# Create AI project with OpenAI integration examples  
spinbox create ai-app --profile ai-llm --with-examples

# Add examples to existing project
spinbox add --redis --with-examples
```

### 🔧 Automatic Dependency Management

Spinbox automatically manages dependencies with the `--with-deps` flag:

```bash
# Create project with automatic dependency management
spinbox create myproject --fastapi --postgresql --with-deps

# Add component with dependencies to existing project
spinbox add --chroma --with-deps
```

**What you get:**
- **Python**: All packages added to `requirements.txt` (FastAPI, SQLAlchemy, Redis, etc.)
- **Node.js**: All packages added to `package.json` (Next.js, React, TypeScript, etc.)
- **Installation scripts**: `setup-python-deps.sh` and `setup-nodejs-deps.sh` for easy setup
- **Smart detection**: No cross-contamination between Python and Node.js dependencies

See [Dependency Management Guide](docs/user-guide/dependency-management.md) for complete details.

**Example Categories:**
- **Core Components**: FastAPI, Next.js, PostgreSQL, Redis, MongoDB, Chroma
- **AI/LLM Integration**: OpenAI, Anthropic, LangChain, LlamaIndex
- **Component Combinations**: FastAPI + PostgreSQL, Next.js + FastAPI, etc.
- **Data Science**: Pandas, Jupyter, ML pipelines

See [Examples Documentation](docs/examples.md) for complete details.

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

### Component Combinations

**Common patterns:**

- `--postgresql --redis` → Primary storage + caching layer
- `--mongodb --chroma` → Document storage + vector search
- `--fastapi --nextjs --postgresql` → Full-stack web application
- `--fastapi --redis` → API with caching/queue support

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

## 🛠️ CLI Commands

### Project Creation

```bash
spinbox create <name> [options]
  --profile <profile>        # Use predefined profile
  --python, --node          # Base environments
  --fastapi, --nextjs       # Application frameworks
  --postgresql, --mongodb   # Databases
  --redis, --chroma         # Additional storage
  --dry-run                 # Preview without creating
```

### Project Management

```bash
# Add components to existing project
spinbox add --postgresql --redis

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
- [Adding Components](./docs/dev/adding-components.md)
- [Troubleshooting](./docs/troubleshooting.md)

See [docs/README.md](./docs/README.md) for complete documentation index.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
