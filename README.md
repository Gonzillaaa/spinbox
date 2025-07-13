[logo]: https://github.com/Gonzillaaa/spinbox/blob/main/docs/spinbox-logo-cropped.png 'Spinbox'

![Spinbox][logo]

# Spin up containerized prototyping environments in seconds!

Spinbox is a **global CLI tool** for creating customizable development environments using Docker and DevContainers. Build your stack by selecting from predefined profiles or mixing and matching components to create the perfect prototyping environment.

## 🚀 Key Features

- **Global CLI Tool**: Simple commands like `spinbox create myproject --profile web-app`
- **DevContainer-First**: Every project includes DevContainer configuration for VS Code, Cursor, and other editors
- **Modular Components**: Mix and match languages, frameworks, and databases
- **Predefined Profiles**: 5 curated profiles for common development scenarios
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

**Option B: System install:**
```bash
# Install to /usr/local/bin (requires sudo)
sudo bash <(curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh)
```

**Note:** The user installation automatically adds `~/.local/bin` to your PATH by detecting your shell and updating the appropriate profile file (.zshrc, .bashrc, etc.). Just restart your terminal or run `source ~/.bashrc` after installation.

### 2. Create Your First Project

**Using predefined profiles:**
```bash
# Full-stack web application
spinbox create myapp --profile web-app

# API server with caching
spinbox create api-server --profile api-only

# AI/LLM development
spinbox create ai-project --profile ai-llm
```

**Custom component selection:**
```bash
# Simple Python project
spinbox create myproject --python

# API with caching
spinbox create api --fastapi --redis

# Full-stack custom
spinbox create webapp --fastapi --nextjs --postgresql
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

| Component | Flag | Description |
|-----------|------|-------------|
| Python | `--python` | Python 3.12+ DevContainer with virtual environment |
| Node.js | `--node` | Node.js 20+ DevContainer with TypeScript |

### 2. **Application Layer** (API & UI)

| Component | Flag | Port | Description |
|-----------|------|------|-------------|
| FastAPI | `--fastapi` | 8000 | Modern Python API framework (includes Python base) |
| Next.js | `--nextjs` | 3000 | React framework with TypeScript (includes Node.js base) |

### 3. **Storage Layer** (Data Persistence)

| Component | Flag | Port | Architectural Role | Best For |
|-----------|------|------|-------------------|----------|
| PostgreSQL | `--postgresql` | 5432 | Primary Storage | Relational data, with PGVector for embeddings |
| MongoDB | `--mongodb` | 27017 | Alternative Storage | Document-oriented data, flexible schemas |
| Redis | `--redis` | 6379 | Caching Layer | High-performance caching and queues |
| Chroma | `--chroma` | - | Vector Search | AI/ML embeddings and similarity search |

### Component Combinations

**Common patterns:**
- `--postgresql --redis` → Primary storage + caching layer
- `--mongodb --chroma` → Document storage + vector search
- `--fastapi --nextjs --postgresql` → Full-stack web application
- `--fastapi --redis` → API with caching/queue support

## 🎯 Predefined Profiles

| Profile | Description | Components | Use Case |
|---------|-------------|------------|----------|
| `web-app` | Full-stack web application | FastAPI + Next.js + PostgreSQL | Complete web applications |
| `api-only` | API server with caching | FastAPI + PostgreSQL + Redis | Backend API services |
| `data-science` | Data analysis environment | Python + PostgreSQL | Data science and analytics |
| `ai-llm` | AI/LLM prototyping | Python + PostgreSQL + Chroma | AI and machine learning |
| `minimal` | Basic environment | Python | Simple prototyping |

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